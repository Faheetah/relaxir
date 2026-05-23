defmodule Relaxir.Inventory do
  @moduledoc """
  Provides functions for managing user inventory items and inventory labels.

  This module handles all inventory-related operations including:
  - Listing inventory items (now called Items) for a user
  - Creating, updating, and deleting items
  - Managing inventory amounts
  - Managing inventory labels (new Inventory model)
  - Grouping items by ingredient categories
  """

  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.Inventory.Item
  alias Relaxir.Inventory.Inventory
  alias Relaxir.Ingredients.Ingredient

  @item_preloads [
    :unit,
    :user,
    :inventory,
    ingredient: [
      parent_ingredient: [
        parent_ingredient: :parent_ingredient
      ],
      child_ingredients: :child_ingredients
    ]
  ]

  @inventory_preloads [
    :user,
    :items
  ]

  # Item functions (formerly inventory items)

  @doc """
  Returns the list of items for a given user.

  ## Examples

      iex> list_user_items(123)
      [%Item{}, ...]

  """
  def list_user_items(user_id) do
    Item
    |> where([i], i.user_id == ^user_id)
    |> preload(^@item_preloads)
    |> order_by([i], asc: i.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(123)
      %Item{}

      iex> get_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(id) do
    Item
    |> preload(^@item_preloads)
    |> Repo.get!(id)
  end

  @doc """
  Gets an item by user and ingredient.

  Returns `nil` if not found.

  ## Examples

      iex> get_item_by_ingredient(123, 456)
      %Item{}

      iex> get_item_by_ingredient(123, 999)
      nil

  """
  def get_item_by_ingredient(user_id, ingredient_id) do
    Item
    |> where([i], i.user_id == ^user_id and i.ingredient_id == ^ingredient_id)
    |> preload(^@item_preloads)
    |> Repo.one()
  end

  @doc """
  Creates a new item.

  ## Examples

      iex> create_item(%{user_id: 1, ingredient_id: 2, amount: 5})
      {:ok, %Item{}}

      iex> create_item(%{user_id: 1})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(attrs \\ %{}) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an item.

  ## Examples

      iex> update_item(item, %{amount: 10})
      {:ok, %Item{}}

      iex> update_item(item, %{amount: -1})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the amount of an item by a delta value.

  ## Examples

      iex> update_item_amount(item, 5)  # increase by 5
      {:ok, %Item{amount: 10}}

      iex> update_item_amount(item, -3) # decrease by 3
      {:ok, %Item{amount: 2}}

  """
  def update_item_amount(%Item{} = item, delta) do
    item
    |> Item.amount_changeset(delta)
    |> Repo.update()
  end

  @doc """
  Toggles the restock flag on an item.

  ## Examples

      iex> toggle_item_restock(item)
      {:ok, %Item{restock: true}}

      iex> toggle_item_restock(item)
      {:ok, %Item{restock: false}}

  """
  def toggle_item_restock(%Item{} = item) do
    item
    |> Ecto.Changeset.change(restock: not item.restock)
    |> Repo.update()
  end

  @doc """
  Deletes an item.

  ## Examples

      iex> delete_item(item)
      {:ok, %Item{}}

      iex> delete_item(item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(item)
      %Ecto.Changeset{data: %Item{}}

  """
  def change_item(%Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end

  @doc """
  Groups items by their top-level parent ingredient.

  Returns a map where keys are top-level ingredient names (or "Uncategorized"
  for ingredients without a parent) and values are lists of items.

  ## Examples

      iex> get_items_grouped_by_parent(123)
      %{
        "Fruits" => [%Item{ingredient: %Ingredient{name: "apple"}}, ...],
        "Vegetables" => [%Item{ingredient: %Ingredient{name: "carrot"}}, ...],
        "Uncategorized" => [%Item{ingredient: %Ingredient{name: "salt"}}, ...]
      }

  """
  def get_items_grouped_by_parent(user_id) do
    get_items_grouped_by_parent(user_id, %{})
  end

  @doc """
  Groups items by their top-level parent ingredient with optional filters.

  Filters:
    - `:inventory_id` - filter by inventory label ID (nil for unlabeled)
    - `:restock_only` - when true, only show items with restock=true
    - `:search` - text search on item name or ingredient name

  ## Examples

      iex> get_items_grouped_by_parent(123, %{inventory_id: 1, restock_only: true, search: "apple"})
      %{"Fruits" => [%Item{ingredient: %Ingredient{name: "apple"}}]}

  """
  def get_items_grouped_by_parent(user_id, filters) do
    query =
      Item
      |> where([i], i.user_id == ^user_id)
      |> apply_inventory_filter(filters[:inventory_id])
      |> apply_restock_filter(filters[:restock_only])
      |> apply_search_filter(filters[:search])
      |> preload(^@item_preloads)
      |> order_by([i], asc: i.inserted_at)

    items = Repo.all(query)

    Enum.group_by(items, fn item ->
      get_top_level_parent_name(item.ingredient)
    end)
  end

  defp apply_inventory_filter(query, nil), do: query
  defp apply_inventory_filter(query, ""), do: query

  defp apply_inventory_filter(query, "unlabeled") do
    where(query, [i], is_nil(i.inventory_id))
  end

  defp apply_inventory_filter(query, inventory_id) when is_binary(inventory_id) do
    apply_inventory_filter(query, String.to_integer(inventory_id))
  end

  defp apply_inventory_filter(query, inventory_id) do
    where(query, [i], i.inventory_id == ^inventory_id)
  end

  defp apply_restock_filter(query, true), do: where(query, [i], i.restock == true)
  defp apply_restock_filter(query, _), do: query

  defp apply_search_filter(query, nil), do: query
  defp apply_search_filter(query, ""), do: query

  defp apply_search_filter(query, search) do
    search_pattern = "%#{search}%"

    query
    |> join(:left, [i], ing in assoc(i, :ingredient))
    |> where([i, ing], ilike(i.name, ^search_pattern) or ilike(ing.name, ^search_pattern))
  end

  defp get_top_level_parent_name(ingredient) do
    case ingredient.parent_ingredient do
      nil ->
        "Uncategorized"

      %Ecto.Association.NotLoaded{} ->
        # Association not loaded, treat as uncategorized
        "Uncategorized"

      parent ->
        # Traverse up the parent hierarchy until we find a top-level parent
        # (where parent_ingredient.parent_ingredient_id is nil)
        traverse_to_top_level(parent)
    end
  end

  defp traverse_to_top_level(ingredient) do
    case ingredient.parent_ingredient do
      nil ->
        # This is a top-level parent
        ingredient.name

      %Ecto.Association.NotLoaded{} ->
        # Association not loaded, stop here
        ingredient.name

      parent ->
        # Continue traversing up
        traverse_to_top_level(parent)
    end
  end

  @doc """
  Searches for ingredients that match a query string.

  Returns ingredients that are not already in the user's items.

  ## Examples

      iex> search_ingredients_not_in_items(123, "apple")
      [%Ingredient{name: "apple"}, ...]

  """
  def search_ingredients_not_in_items(user_id, query) when is_binary(query) do
    # Get ingredient IDs already in user's items
    existing_ingredient_ids =
      Item
      |> where([i], i.user_id == ^user_id)
      |> select([i], i.ingredient_id)
      |> Repo.all()

    # Search for ingredients matching query, excluding those already in items
    # Also exclude top-level category ingredients (those with no parent that have children)
    from(i in Ingredient,
      left_join: c in Ingredient,
      on: c.parent_ingredient_id == i.id,
      where: ilike(i.name, ^"%#{query}%"),
      where: i.id not in ^existing_ingredient_ids,
      where: not is_nil(i.parent_ingredient_id) or is_nil(c.id),
      order_by: [asc: i.name],
      limit: 20,
      group_by: i.id,
      select: i
    )
    |> Repo.all()
  end

  @doc """
  Gets all items that are "out" (amount = 0) and have been in items
  for more than 5 minutes (to avoid warning for newly added items).

  ## Examples

      iex> get_out_of_stock_items(123)
      [%Item{amount: 0}, ...]

  """
  def get_out_of_stock_items(user_id) do
    five_minutes_ago = DateTime.utc_now() |> DateTime.add(-300, :second)

    Item
    |> where([i], i.user_id == ^user_id and i.amount == 0)
    |> where([i], i.inserted_at < ^five_minutes_ago)
    |> preload(^@item_preloads)
    |> Repo.all()
  end

  # Inventory label functions (new)

  @doc """
  Returns the list of inventory labels for a given user.

  ## Examples

      iex> list_inventory_labels(123)
      [%Inventory{}, ...]

  """
  def list_inventory_labels(user_id) do
    Inventory
    |> where([i], i.user_id == ^user_id)
    |> preload(^@inventory_preloads)
    |> order_by([i], asc: i.name)
    |> Repo.all()
  end

  @doc """
  Gets a single inventory label.

  Raises `Ecto.NoResultsError` if the Inventory does not exist.

  ## Examples

      iex> get_inventory_label!(123)
      %Inventory{}

      iex> get_inventory_label!(456)
      ** (Ecto.NoResultsError)

  """
  def get_inventory_label!(id) do
    Inventory
    |> preload(^@inventory_preloads)
    |> Repo.get!(id)
  end

  @doc """
  Creates a new inventory label.

  ## Examples

      iex> create_inventory_label(%{user_id: 1, name: "Pantry"})
      {:ok, %Inventory{}}

      iex> create_inventory_label(%{user_id: 1})
      {:error, %Ecto.Changeset{}}

  """
  def create_inventory_label(attrs \\ %{}) do
    %Inventory{}
    |> Inventory.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an inventory label.

  ## Examples

      iex> update_inventory_label(inventory, %{name: "Refrigerator"})
      {:ok, %Inventory{}}

      iex> update_inventory_label(inventory, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def update_inventory_label(%Inventory{} = inventory, attrs) do
    inventory
    |> Inventory.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an inventory label.

  ## Examples

      iex> delete_inventory_label(inventory)
      {:ok, %Inventory{}}

      iex> delete_inventory_label(inventory)
      {:error, %Ecto.Changeset{}}

  """
  def delete_inventory_label(%Inventory{} = inventory) do
    Repo.delete(inventory)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking inventory label changes.

  ## Examples

      iex> change_inventory_label(inventory)
      %Ecto.Changeset{data: %Inventory{}}

  """
  def change_inventory_label(%Inventory{} = inventory, attrs \\ %{}) do
    Inventory.changeset(inventory, attrs)
  end

  # Backward compatibility aliases

  @deprecated "Use list_user_items/1 instead"
  def list_user_inventory(user_id), do: list_user_items(user_id)

  @deprecated "Use get_item!/1 instead"
  def get_inventory!(id), do: get_item!(id)

  @deprecated "Use get_item_by_ingredient/2 instead"
  def get_inventory_by_ingredient(user_id, ingredient_id), do: get_item_by_ingredient(user_id, ingredient_id)

  @deprecated "Use create_item/1 instead"
  def create_inventory_item(attrs), do: create_item(attrs)

  @deprecated "Use update_item/2 instead"
  def update_inventory_item(%Item{} = item, attrs), do: update_item(item, attrs)

  @deprecated "Use update_item_amount/2 instead"
  def update_inventory_amount(%Item{} = item, delta), do: update_item_amount(item, delta)

  @deprecated "Use delete_item/1 instead"
  def delete_inventory_item(%Item{} = item), do: delete_item(item)

  @deprecated "Use change_item/2 instead"
  def change_inventory_item(%Item{} = item, attrs), do: change_item(item, attrs)

  @deprecated "Use get_items_grouped_by_parent/1 instead"
  def get_inventory_grouped_by_parent(user_id), do: get_items_grouped_by_parent(user_id)

  @deprecated "Use search_ingredients_not_in_items/2 instead"
  def search_ingredients_not_in_inventory(user_id, query), do: search_ingredients_not_in_items(user_id, query)
end
