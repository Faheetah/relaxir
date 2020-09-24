defmodule Relaxir.Recipes do
  import Ecto.Query
  alias Relaxir.Repo

  alias Relaxir.Categories
  alias Relaxir.Ingredients
  alias Relaxir.IngredientParser
  alias Relaxir.Recipes.Recipe

  @preload [:recipe_ingredients, :ingredients, :units, :recipe_categories, :categories]

  def list_recipes do
    Repo.all(order_by(Recipe, desc: :updated_at))
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
        try do
          Relaxir.Search.set(Relaxir.Recipes.Recipe, :title, recipe.title)
        catch
          :exit, _ -> nil
        end
        recipe.recipe_ingredients
        |> Enum.each(fn i ->
          try do
            Relaxir.Search.set(Relaxir.Ingredients.Ingredient, :name, i.ingredient.name)
          catch
            :exit, _ -> nil
          end
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
      try do
        Relaxir.Search.delete(Relaxir.Recipes.Recipe, :title, recipe.title)
        Relaxir.Search.set(Relaxir.Recipes.Recipe, :title, title)
      catch
        :exit, _ -> nil
      end
    end
    with %{recipe_ingredients: recipe_ingredients} <- changeset.changes do
      recipe_ingredients
      |> Enum.each(fn i ->
        with %{action: :insert, changes: %{ingredient: %{changes: %{name: name}}}} <- i do
          try do
            Relaxir.Search.set(Relaxir.Ingredients.Ingredient, :name, name)
          catch
            :exit, _ -> nil
          end
        end
      end)
    end
    changeset
  end

  def delete_recipe(%Recipe{} = recipe) do
    try do
      Relaxir.Search.delete(Relaxir.Recipes.Recipe, :title, recipe.title)
    catch
      :exit, _ -> nil
    end
    Repo.delete(recipe)
  end

  def change_recipe(%Recipe{} = recipe, attrs \\ %{}) do
    Recipe.changeset(recipe, map_attrs(attrs))
  end

  def map_attrs(attrs, recipe \\ %Recipe{recipe_categories: [], recipe_ingredients: []}) do
    attrs
    |> map_categories()
    |> map_existing_categories(recipe)
    |> IngredientParser.map_ingredients()
    |> IngredientParser.map_existing_ingredients(recipe)
  end

  def map_categories(attrs) when is_map_key(attrs, "categories") do
    fetched_categories = Categories.get_categories_by_name!(attrs["categories"])

    categories =
      attrs["categories"]
      |> Enum.map(fn name ->
        case Enum.find(fetched_categories, fn c -> c.name == name end) do
          nil -> %{category: %{name: name}}
          category -> %{category_id: category.id}
        end
      end)

    Map.put(attrs, "recipe_categories", categories)
  end

  def map_categories(attrs), do: attrs

  def map_existing_categories(attrs, recipe) do
    current_recipe_categories =
      recipe.recipe_categories
      |> Enum.reduce(
        [],
        fn ri, acc ->
          [%{id: ri.id, category: %{id: ri.category.id}} | acc]
        end
      )

    recipe_categories =
      (attrs["recipe_categories"] || [])
      |> Enum.map(fn i ->
        case i do
          %{:category_id => id} ->
            Enum.find(
              current_recipe_categories,
              %{recipe_id: recipe.id, category_id: id},
              fn cri ->
                if cri.category.id == id do
                  cri
                end
              end
            )

          _ ->
            i
        end
      end)

    Map.put(attrs, "recipe_categories", recipe_categories)
  end
end
