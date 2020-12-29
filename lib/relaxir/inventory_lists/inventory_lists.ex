defmodule Relaxir.InventoryLists do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.InventoryLists.InventoryList

  def list_inventory_lists do
    Repo.all(InventoryList)
  end

  def get_inventory_list!(id) do
    InventoryList
    |> preload(:ingredients)
    |> Repo.get!(id)
  end

  def create_inventory_list(attrs \\ %{}) do
    %InventoryList{}
    |> InventoryList.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, inventory_list} ->
        {:ok, Repo.preload(inventory_list, :ingredients)}
      error ->
        error
    end
  end

  def add_ingredient(%InventoryList{} = inventory_list, ingredient_id, note \\ nil) do
    case Enum.find(inventory_list.ingredient_inventory_lists, fn igl -> igl.ingredient.id == ingredient_id end) do
      nil ->
        ingredient_inventory_lists = [%{ingredient_id: ingredient_id, note: note} | inventory_list.ingredient_inventory_lists]

        inventory_list
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:ingredient_inventory_lists, ingredient_inventory_lists)
        |> Repo.update()
        :ok
      _ ->
        {:error, "Already added"}
    end
  end

  def remove_ingredient(%InventoryList{} = inventory_list, ingredient_id) do
    ingredient_inventory_lists =
      inventory_list.ingredient_inventory_lists
      |> Enum.filter(fn i -> i.ingredient.id != ingredient_id end)

    inventory_list
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:ingredient_inventory_lists, ingredient_inventory_lists)
    |> Repo.update()
  end

  def update_inventory_list(%InventoryList{} = inventory_list, attrs) do
    inventory_list
    |> InventoryList.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, inventory_list} ->
        {:ok, Repo.preload(inventory_list, :ingredients)}
      error ->
        error
    end
  end

  def delete_inventory_list(%InventoryList{} = inventory_list) do
    Repo.delete(inventory_list)
  end

  def change_inventory_list(%InventoryList{} = inventory_list, attrs \\ %{}) do
    InventoryList.changeset(inventory_list, attrs)
  end
end

