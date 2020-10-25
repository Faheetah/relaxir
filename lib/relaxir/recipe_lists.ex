defmodule Relaxir.RecipeLists do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.RecipeLists.RecipeList

  def list_recipe_lists do
    Repo.all(RecipeList)
  end

  def get_recipe_list!(id) do
    RecipeList
    |> preload(:recipes)
    |> Repo.get!(id)
  end

  def create_recipe_list(attrs \\ %{}) do
    %RecipeList{}
    |> RecipeList.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, recipe_list} ->
        {:ok, Repo.preload(recipe_list, :recipes)}
      error ->
        error
    end
  end

  def update_recipe_list(%RecipeList{} = recipe_list, attrs) do
    recipe_list
    |> RecipeList.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, recipe_list} ->
        {:ok, Repo.preload(recipe_list, :recipes)}
      error ->
        error
    end
  end

  def delete_recipe_list(%RecipeList{} = recipe_list) do
    Repo.delete(recipe_list)
  end

  def change_recipe_list(%RecipeList{} = recipe_list, attrs \\ %{}) do
    RecipeList.changeset(recipe_list, attrs)
  end
end
