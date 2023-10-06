defmodule Relaxir.GroceryLists do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.GroceryLists.GroceryList

  def list_grocery_lists do
    Repo.all(GroceryList)
  end

  def get_grocery_list!(id) do
    GroceryList
    |> preload(:ingredients)
    |> Repo.get!(id)
  end

  def create_grocery_list(attrs \\ %{}) do
    %GroceryList{}
    |> GroceryList.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, grocery_list} ->
        {:ok, Repo.preload(grocery_list, :ingredients)}

      error ->
        error
    end
  end

  def add_ingredient(%GroceryList{} = grocery_list, ingredient_id) do
    case Enum.find(grocery_list.ingredient_grocery_lists, fn igl -> igl.ingredient.id == ingredient_id end) do
      nil ->
        ingredient_grocery_lists = [%{ingredient_id: ingredient_id} | grocery_list.ingredient_grocery_lists]

        grocery_list
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:ingredient_grocery_lists, ingredient_grocery_lists)
        |> Repo.update()

        :ok

      _ ->
        {:error, "Already added"}
    end
  end

  def remove_ingredient(%GroceryList{} = grocery_list, ingredient_id) do
    ingredient_grocery_lists =
      grocery_list.ingredient_grocery_lists
      |> Enum.filter(fn i -> i.ingredient.id != ingredient_id end)

    grocery_list
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:ingredient_grocery_lists, ingredient_grocery_lists)
    |> Repo.update()
  end

  def update_grocery_list(%GroceryList{} = grocery_list, attrs) do
    grocery_list
    |> GroceryList.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, grocery_list} ->
        {:ok, Repo.preload(grocery_list, :ingredients)}

      error ->
        error
    end
  end

  def delete_grocery_list(%GroceryList{} = grocery_list) do
    Repo.delete(grocery_list)
  end

  def change_grocery_list(%GroceryList{} = grocery_list, attrs \\ %{}) do
    GroceryList.changeset(grocery_list, attrs)
  end
end
