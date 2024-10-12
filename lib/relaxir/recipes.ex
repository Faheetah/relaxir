defmodule Relaxir.Recipes do
  @moduledoc false

  import Ecto.Query

  alias Relaxir.Repo
  alias Relaxir.Categories
  alias Relaxir.Ingredients
  alias Relaxir.RecipeIngredient
  alias Relaxir.Recipes.Recipe

  @preload [
    [recipe_ingredients: from(ri in RecipeIngredient, order_by: ri.order)],
    [
      ingredients: [
        source_recipe: [
          recipe_ingredients: from(ri in RecipeIngredient, order_by: ri.order, preload: [:ingredient, :unit])
        ]
      ]
    ],
    :units,
    :recipe_categories,
    :categories,
    :user
  ]

  def list_recipes do
    Recipe
    |> order_by(desc: :inserted_at)
    |> preload(:user)
    |> preload(:categories)
    |> Repo.all()
  end

  def list_recipes(user_id) do
    query = from r in Recipe, where: r.user_id == ^user_id, order_by: [desc: r.inserted_at], preload: [:user, :categories]
    Repo.all(query)
  end

  def list_draft_recipes do
    query = from r in Recipe, where: r.published == false or is_nil(r.published), order_by: [desc: r.inserted_at], preload: [:user, :categories]
    Repo.all(query)
  end

  def list_published_recipes do
    query = from r in Recipe, where: r.published == true, order_by: [desc: r.inserted_at], preload: [:user, :categories]
    Repo.all(query)
  end

  def get_recipe!(id) do
    Recipe
    |> preload(^@preload)
    |> Repo.get!(id)
  end

  def get_recipe_by_name!(title) do
    Repo.get_by(Relaxir.Recipes.Recipe, title: title)
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

  # sobelow_skip ["Traversal"]
  # traversal is not possible due to dest coming from application config
  def delete_recipe(%Recipe{} = recipe) do
    delete_cache(recipe)
    dest = Application.fetch_env!(:relaxir, RelaxirWeb.UploadLive)[:dest]

    # TODO move this to a separate module to handle physical file access
    if recipe.image_filename do
      :ok = File.rm(Path.join(dest, "#{recipe.image_filename}-full.jpg"))
    end

    Repo.delete(recipe)
  end

  def change_recipe(%Recipe{} = recipe, attrs \\ %{}) do
    Recipe.changeset(recipe, map_attrs(attrs))
  end

  def map_ingredients(attrs) do
    attrs
    |> Ingredients.Parser.map_ingredients()
    |> Map.get("recipe_ingredients", [])
    |> Enum.map(fn i ->
      case i do
        %{ingredient_id: id} ->
          Map.put(
            i,
            :ingredient,
            Relaxir.Repo.get!(Ingredients.Ingredient, id)
          )

        i ->
          i
      end
    end)
    |> Enum.map(fn i ->
      case i do
        %{unit_id: id} -> Map.put(i, :unit, Relaxir.Repo.get!(Units.Unit, id))
        i -> i
      end
    end)
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
    Invert.set(Relaxir.Recipes.Recipe, :title, {recipe.title, [recipe.title, recipe.id]})
  end

  def delete_cache(recipe) do
    Invert.delete(Relaxir.Recipes.Recipe, :title, {recipe.title, [recipe.title, recipe.id]})
  end

  def get_recipe_ingredient_names(changeset) do
    changeset
    |> Map.get(:changes)
    |> Map.get(:recipe_ingredients)
    |> Enum.map(&get_ingredient_name/1)
  end

  defp get_ingredient_name(%{changes: %{ingredient_id: id}} = ingredient) do
    name = Relaxir.Repo.get!(Relaxir.Ingredients.Ingredient, id).name
    Map.merge(ingredient, %{changes: %{ingredient: %{changes: %{name: name}}}}, fn _, m1, m2 -> Map.merge(m1, m2) end)
  end

  defp get_ingredient_name(%{changes: %{unit_id: id}} = ingredient) do
    unit = Relaxir.Repo.get!(Units.Unit, id)

    cond do
      Map.get(ingredient.changes, :amount) == nil -> ingredient
      ingredient.changes.amount > 1 -> merge_ingredient_changes(ingredient, Inflex.pluralize(unit.name))
      true -> merge_ingredient_changes(ingredient, Inflex.singularize(unit.name))
    end
  end

  defp get_ingredient_name(ingredient), do: ingredient

  defp merge_ingredient_changes(ingredient, unit_name) do
    Map.merge(ingredient, %{changes: %{unit: unit_name}}, fn _, m1, m2 -> Map.merge(m1, m2) end)
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
