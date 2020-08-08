defmodule Relaxir.Recipes do
  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias Relaxir.Repo

  alias Relaxir.Recipes.Recipe
  alias Relaxir.Ingredients
  alias Relaxir.Ingredients.Ingredient

  def list_recipes do
    Repo.all(Recipe)
    |> Repo.preload(:ingredients)
  end

  def get_recipe!(id) do
    Recipe
    |> preload(:ingredients)
    |> Repo.get!(id)
  end

  def create_recipe(attrs \\ %{}) do
    %Recipe{}
    |> Recipe.changeset(attrs)
    |> put_assoc(:ingredients, parse_ingredients(attrs))
    |> Repo.insert()
  end

  def update_recipe(%Recipe{} = recipe, attrs) do
    recipe
    |> Recipe.changeset(attrs)
    # here we need to instead of just parse_ingredients, 
    # parse each one and add it to the changeset, not 
    # blindly create it
    |> put_assoc(:ingredients, parse_ingredients(attrs))
    |> Repo.update()
  end

  def delete_recipe(%Recipe{} = recipe) do
    Repo.delete(recipe)
  end

  def change_recipe(%Recipe{} = recipe, attrs \\ %{}) do
    Recipe.changeset(recipe, attrs)
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
