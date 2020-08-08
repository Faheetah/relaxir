defmodule Relaxir.Recipes do
  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias Relaxir.Repo

  alias Relaxir.Recipes.Recipe
  alias Relaxir.Ingredients
  alias Relaxir.Ingredients.Ingredient
  alias Relaxir.Categories
  alias Relaxir.Categories.Category

  def list_recipes do
    Repo.all(Recipe)
    |> Repo.preload([:ingredients, :categories])
  end

  def get_recipe!(id) do
    Recipe
    |> preload([:ingredients, :categories])
    |> Repo.get!(id)
  end

  def create_recipe(attrs \\ %{}) do
    %Recipe{}
    |> Recipe.changeset(attrs)
    |> put_assoc(:ingredients, parse_ingredients(attrs))
    |> put_assoc(:categories, parse_categories(attrs))
    |> Repo.insert()
  end

  def update_recipe(%Recipe{} = recipe, attrs) do
    recipe
    |> Recipe.changeset(attrs)
    |> put_assoc(:ingredients, parse_ingredients(attrs))
    |> put_assoc(:categories, parse_categories(attrs))
    |> Repo.update()
  end

  def delete_recipe(%Recipe{} = recipe) do
    Repo.delete(recipe)
  end

  def change_recipe(%Recipe{} = recipe, attrs \\ %{}) do
    Recipe.changeset(recipe, attrs)
  end

  defp parse_categories(nil), do: []

  defp parse_categories(attrs) do
    (attrs["categories"] || "")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(& &1 == "")
    |> Enum.map(&get_or_create_category/1)
  end

  defp get_or_create_category(category) do
    case Categories.get_category_by_name!(category) do
      nil -> Category.changeset(%Category{}, %{name: category})
      category -> category
    end
  end

  defp parse_ingredients(nil), do: []

  defp parse_ingredients(attrs) do
    (attrs["ingredients"] || "")
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(& &1 == "")
    |> Enum.map(&get_or_create_ingredient/1)
  end

  defp get_or_create_ingredient(ingredient) do
    case Ingredients.get_ingredient_by_name!(ingredient) do
      nil -> Ingredient.changeset(%Ingredient{}, %{name: ingredient})
      ingredient -> ingredient
    end
  end
end
