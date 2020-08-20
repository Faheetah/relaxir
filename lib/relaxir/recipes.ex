defmodule Relaxir.Recipes do
  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias Relaxir.Repo

  alias Relaxir.Recipes.Recipe

  def list_recipes do
    Repo.all(Recipe)
  end

  def get_recipe!(id) do
    Recipe
    |> preload([:recipe_ingredients, :ingredients, :categories])
    |> Repo.get!(id)
  end

  def create_recipe!(attrs) do
    {:ok, recipe} = create_recipe(attrs)
    recipe
  end

  def create_recipe(attrs) do
    %Recipe{}
    |> Recipe.changeset(attrs)
    |> put_assoc(:categories, attrs["categories"])
    |> Repo.insert()
  end

  def update_recipe(%Recipe{} = recipe, attrs) do
    recipe
    |> Recipe.changeset(attrs)
    |> put_assoc(:categories, attrs["categories"])
    |> Repo.update()
  end

  def delete_recipe(%Recipe{} = recipe) do
    Repo.delete(recipe)
  end

  def change_recipe(%Recipe{} = recipe, attrs \\ %{}) do
    Recipe.changeset(recipe, attrs)
  end
end
