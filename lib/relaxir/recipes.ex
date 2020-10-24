defmodule Relaxir.Recipes do
  import Ecto.Query
  alias Relaxir.Repo
  import Ecto.Changeset

  alias Relaxir.Categories
  alias Relaxir.Ingredients
  alias Relaxir.Recipes.Recipe

  @preload [:recipe_ingredients, :ingredients, :units, :recipe_categories, :categories, :user]

  def list_recipes do
    Repo.all(order_by(Recipe, desc: :updated_at))
  end

  def list_recipes(user_id) do
    query = from r in Recipe, where: r.user_id == ^user_id, order_by: [desc: r.updated_at]
    Repo.all(query)
  end

  def list_draft_recipes do
    query = from r in Recipe, where: r.published == false or is_nil(r.published), order_by: [desc: r.updated_at]
    Repo.all(query)
  end

  def list_published_recipes do
    query = from r in Recipe, where: r.published == true, order_by: [desc: r.updated_at]
    Repo.all(query)
  end

  def get_recipe!(id) do
    Recipe
    |> preload(^@preload)
    |> Repo.get!(id)
  end

  def create_recipe!(attrs) do
    {:ok, recipe} = create_recipe(attrs)
    recipe
  end

  def create_recipe(attrs) do
    attrs = map_attrs(attrs)

    %Recipe{}
    |> Recipe.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, recipe} ->
        recipe = Repo.preload(recipe, @preload)
        insert_cache(recipe)

        recipe.recipe_ingredients
        |> Enum.each(fn recipe_ingredient ->
          Relaxir.Ingredients.insert_cache(recipe_ingredient.ingredient)
        end)

        {:ok, recipe}

      error ->
        error
    end
  end

  def update_recipe(%Recipe{} = recipe, original_attrs) do
    attrs = map_attrs(original_attrs, recipe)

    case attrs["errors"] do
      {:error, error} ->
        {
          :error,
          recipe
          |> Recipe.changeset(Map.merge(original_attrs, %{"ingredients" => attrs["errors"]}))
          |> Ecto.Changeset.add_error(:ingredients, error, validation: :required)
        }

      _ ->
        recipe
        |> Recipe.changeset(attrs)
        |> do_changeset_update(recipe)
        |> Repo.update()
        |> case do
          {:ok, recipe} ->
            {:ok, Repo.preload(recipe, [:recipe_ingredients, :ingredients, :recipe_categories, :categories])}

          error ->
            error
        end
    end
  end

  def do_changeset_update(changeset, recipe) do
    with %{title: title} <- changeset.changes do
      insert_cache(recipe)
      delete_cache(%{title: title, id: recipe.id})
    end

    with %{recipe_ingredients: recipe_ingredients} <- changeset.changes do
      recipe_ingredients
      |> Enum.each(fn ingredient ->
        with %{action: :insert, changes: %{ingredient_id: ingredient_id, ingredient: %{changes: %{name: name}}}} <- ingredient do
          Relaxir.Ingredients.insert_cache(%{name: name, id: ingredient_id})
        end
      end)
    end

    changeset
  end

  def delete_recipe(%Recipe{} = recipe) do
    delete_cache(recipe)
    Repo.delete(recipe)
  end

  def change_recipe(%Recipe{} = recipe, attrs \\ %{}) do
    Recipe.changeset(recipe, map_attrs(attrs))
  end

  def map_attrs(attrs, recipe \\ %Recipe{recipe_categories: [], recipe_ingredients: []}) do
    attrs
    |> Categories.Parser.downcase_categories()
    |> Categories.Parser.map_categories()
    |> Categories.Parser.map_existing_categories(recipe)
    |> Ingredients.Parser.downcase_ingredients()
    |> Ingredients.Parser.map_ingredients()
    |> Ingredients.Parser.map_existing_ingredients(recipe)
  end

  def insert_cache(recipe) do
    Relaxir.Search.set(Relaxir.Recipes.Recipe, :title, {recipe.title, [recipe.title, recipe.id]})
  end

  def delete_cache(recipe) do
    Relaxir.Search.delete(Relaxir.Recipes.Recipe, :title, {recipe.title, [recipe.title, recipe.id]})
  end

  def get_recipe_ingredient_suggestions(changeset) do
    changeset
    |> get_recipe_ingredient_names()
    |> Enum.map(fn ingredient ->
      ingredient_name =
        ingredient
        |> Map.get(:changes)
        |> Map.get(:ingredient)
        |> Map.get(:changes)
        |> Map.get(:name)

      cond do
        ingredient_name == nil ->
          ingredient

        true ->
          case Relaxir.Search.get(Ingredients.Ingredient, :name, ingredient_name) do
            {:ok, suggestion} ->
              {{_, s, _}, score} = hd(suggestion)

              cond do
                score > 1 ->
                  put_change(ingredient, :suggestion, %{name: String.downcase(s), type: "ingredient", score: round(score * 10)})

                true ->
                  case Relaxir.Search.get(Ingredients.Food, :description, ingredient_name) do
                    {:ok, suggestion} ->
                      {{_, s, _}, score} = hd(suggestion)

                      cond do
                        score > 1 ->
                          put_change(ingredient, :suggestion, %{name: String.downcase(s), type: "USDA", score: round(score * 10)})

                        true ->
                          ingredient
                      end

                    {:error, :not_found} ->
                      ingredient
                  end
              end

            {:error, :not_found} ->
              case Relaxir.Search.get(Ingredients.Food, :description, ingredient_name) do
                {:ok, suggestion} ->
                  {{_, s, _}, score} = hd(suggestion)

                  cond do
                    score > 1 -> put_change(ingredient, :suggestion, %{name: String.downcase(s), type: "USDA", score: round(score * 10)})
                    true -> ingredient
                  end

                {:error, :not_found} ->
                  ingredient
              end
          end
      end
    end)
  end

  def get_recipe_ingredient_names(changeset) do
    changeset
    |> Map.get(:changes)
    |> Map.get(:recipe_ingredients)
    |> Enum.map(fn i ->
      case i.changes do
        %{ingredient_id: id} ->
          name = Relaxir.Repo.get!(Relaxir.Ingredients.Ingredient, id).name
          Map.merge(i, %{changes: %{ingredient: %{changes: %{name: name}}}}, fn _, m1, m2 -> Map.merge(m1, m2) end)

        _ ->
          i
      end
    end)
    |> Enum.map(fn i ->
      case i.changes do
        %{unit_id: id} ->
          unit = Relaxir.Repo.get!(Ingredients.Unit, id)

          cond do
            Map.get(i.changes, :amount) == nil -> i
            i.changes.amount > 1 -> Map.merge(i, %{changes: %{unit: Inflex.pluralize(unit.name)}}, fn _, m1, m2 -> Map.merge(m1, m2) end)
            true -> Map.merge(i, %{changes: %{unit: Inflex.singularize(unit.name)}}, fn _, m1, m2 -> Map.merge(m1, m2) end)
          end

        _ ->
          i
      end
    end)
  end

  def get_recipe_category_names(changeset) do
    changeset
    |> Map.get(:changes)
    |> Map.get(:recipe_categories)
    |> Enum.map(fn c ->
      case c.changes do
        %{category_id: id} ->
          name = Relaxir.Repo.get!(Relaxir.Categories.Category, id).name

          %{changes: %{category_id: id, category: %{changes: %{name: name}}}}

        _ ->
          c
      end
    end)
  end
end
