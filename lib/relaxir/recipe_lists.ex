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

  def add_recipe(%RecipeList{} = recipe_list, recipe_id) do
    case Enum.find(recipe_list.recipe_recipe_lists, fn rrl -> rrl.recipe.id == recipe_id end) do
      nil ->
        recipe_recipe_lists = [%{recipe_id: recipe_id} | recipe_list.recipe_recipe_lists]

        recipe_list
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:recipe_recipe_lists, recipe_recipe_lists)
        |> Repo.update()
        :ok
      _ ->
        {:error, "Already added"}
    end
  end

  def remove_recipe(%RecipeList{} = recipe_list, recipe_id) do
    recipe_recipe_lists =
      recipe_list.recipe_recipe_lists
      |> Enum.filter(fn r -> r.recipe.id != recipe_id end)

    recipe_list
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:recipe_recipe_lists, recipe_recipe_lists)
    |> Repo.update()
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
