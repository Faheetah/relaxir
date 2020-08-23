defmodule Relaxir.Recipes do
  import Ecto.Query
  alias Relaxir.Repo

  alias Relaxir.Categories
  alias Relaxir.Ingredients
  alias Relaxir.Recipes.Recipe

  @preload [:recipe_ingredients, :ingredients, :units, :recipe_categories, :categories]

  def list_recipes do
    Repo.all(Recipe)
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
    attrs =
      attrs
      |> map_categories
      |> map_ingredients

    %Recipe{}
    |> Recipe.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, recipe} ->
        {:ok, Repo.preload(recipe, @preload)}

      error ->
        error
    end
  end

  def update_recipe(%Recipe{} = recipe, attrs) do
    attrs =
      attrs
      |> map_categories
      |> map_ingredients

    recipe
    |> Recipe.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, recipe} ->
        {:ok, Repo.preload(recipe, [:recipe_ingredients, :ingredients, :recipe_categories, :categories])}

      error ->
        error
    end
  end

  def delete_recipe(%Recipe{} = recipe) do
    Repo.delete(recipe)
  end

  def change_recipe(%Recipe{} = recipe, attrs \\ %{}) do
    Recipe.changeset(recipe, attrs)
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

  def map_ingredients(attrs) when is_map_key(attrs, "ingredients") do
    units = Ingredients.list_units()

    fetched_ingredients =
      attrs["ingredients"]
      |> Enum.map(fn i -> i.name end)
      |> Ingredients.get_ingredients_by_name!()

    ingredients =
      attrs["ingredients"]
      |> Enum.map(fn ingredient ->
        case Enum.find(fetched_ingredients, fn i -> i.name == ingredient.name end) do
          nil -> %{ingredient: ingredient}
          ingredient -> %{ingredient_id: ingredient.id}
        end
        |> map_recipe_ingredient_fields(ingredient, units)
      end)

    Map.put(attrs, "recipe_ingredients", ingredients)
  end

  def map_ingredients(attrs), do: attrs

  def map_recipe_ingredient_fields(attrs, ingredient, units) do
    amount = Map.get(ingredient, :amount)
    unit_name = Map.get(ingredient, :unit)

    cond do
      amount == nil -> attrs
      amount == 1 -> {:ok, Enum.find(units, fn u -> unit_name == u.singular end)}
      amount > 1 -> {:ok, Enum.find(units, fn u -> unit_name == u.plural end)}
      unit_name != nil -> {:error, "Unit \"#{unit_name}\" is invalid"}
      true -> attrs
    end
    |> case do
      {:ok, unit} ->
        attrs
        |> Map.merge(%{
          amount: Map.get(ingredient, :amount),
          unit_id: unit.id,
          note: Map.get(ingredient, :note)
        })

      {:error, error} ->
        {:error, error}

      %{ingredient: %{note: note}} ->
        attrs
        |> Map.merge(%{note: note})

      attrs ->
        attrs
    end
  end
end
