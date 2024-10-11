defmodule Relaxir.InventoryListsTest do
  use Relaxir.DataCase

  alias Relaxir.InventoryLists

  @moduletag skip: "To reimplement"

  describe "inventory_lists" do
    alias Relaxir.InventoryLists.InventoryList

    @valid_attrs %{name: "some name", user_id: 1}
    @update_attrs %{name: "some updated name", user_id: 1}
    @invalid_attrs %{name: nil}

    def inventory_list_fixture(attrs \\ %{}) do
      {:ok, inventory_list} =
        attrs
        |> Enum.into(@valid_attrs)
        |> InventoryLists.create_inventory_list()

      inventory_list
    end

    def map_names(items) do
      Enum.map(items, fn i -> i.name end)
    end

    test "list_inventory_lists/0 returns all inventory_lists" do
      inventory_list = inventory_list_fixture()
      assert map_names(InventoryLists.list_inventory_lists()) == map_names([inventory_list])
    end

    test "get_inventory_list!/1 returns the inventory_list with given id" do
      inventory_list = inventory_list_fixture()
      assert InventoryLists.get_inventory_list!(inventory_list.id) == inventory_list
    end

    test "create_inventory_list/1 with valid data creates a inventory_list" do
      assert {:ok, %InventoryList{} = inventory_list} = InventoryLists.create_inventory_list(@valid_attrs)
      assert inventory_list.name == @valid_attrs.name
    end

    test "create_inventory_list/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = InventoryLists.create_inventory_list(@invalid_attrs)
    end

    test "update_inventory_list/2 with valid data updates the inventory_list" do
      inventory_list = inventory_list_fixture()
      assert {:ok, %InventoryList{} = inventory_list} = InventoryLists.update_inventory_list(inventory_list, @update_attrs)
      assert inventory_list.name == @update_attrs.name
    end

    test "update_inventory_list/2 with invalid data returns error changeset" do
      inventory_list = inventory_list_fixture()
      assert {:error, %Ecto.Changeset{}} = InventoryLists.update_inventory_list(inventory_list, @invalid_attrs)
      assert inventory_list == InventoryLists.get_inventory_list!(inventory_list.id)
    end

    test "delete_inventory_list/1 deletes the inventory_list" do
      inventory_list = inventory_list_fixture()
      assert {:ok, %InventoryList{}} = InventoryLists.delete_inventory_list(inventory_list)
      assert_raise Ecto.NoResultsError, fn -> InventoryLists.get_inventory_list!(inventory_list.id) end
    end

    test "change_inventory_list/1 returns a inventory_list changeset" do
      inventory_list = inventory_list_fixture()
      assert %Ecto.Changeset{} = InventoryLists.change_inventory_list(inventory_list)
    end

    test "add_ingredient/2 adds an ingredient by id" do
      inventory_list = inventory_list_fixture()
      {:ok, ingredient} = Relaxir.Ingredients.create_ingredient(%{"name" => "F"})
      assert :ok = InventoryLists.add_ingredient(inventory_list, ingredient.id)
      assert hd(InventoryLists.get_inventory_list!(inventory_list.id).ingredient_inventory_lists).ingredient.name == ingredient.name
    end

    test "remove_ingredient/2 removes an ingredient by id" do
      inventory_list = inventory_list_fixture()
      {:ok, ingredient} = Relaxir.Ingredients.create_ingredient(%{"name" => "F"})
      InventoryLists.remove_ingredient(inventory_list, ingredient.id)
      assert InventoryLists.get_inventory_list!(inventory_list.id).ingredient_inventory_lists == []
    end
  end
end
