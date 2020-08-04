defmodule Relaxir.Recipes do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.Recipes.Recipe

  def list_recipes do
    Repo.all(Recipe)
  end

  def get_recipe!(id), do: Repo.get!(Recipe, id)

  def create_recipe(attrs \\ %{}) do
    %Recipe{}
    |> Recipe.changeset(attrs)
    |> Repo.insert()
  end

  def update_recipe(%Recipe{} = recipe, attrs) do
    recipe
    |> Recipe.changeset(attrs)
    |> Repo.update()
  end

  def delete_recipe(%Recipe{} = recipe) do
    Repo.delete(recipe)
  end

  def change_recipe(%Recipe{} = recipe, attrs \\ %{}) do
    Recipe.changeset(recipe, attrs)
  end
end
