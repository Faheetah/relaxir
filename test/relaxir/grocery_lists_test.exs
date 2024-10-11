defmodule Relaxir.GroceryListsTest do
  use Relaxir.DataCase

  alias Relaxir.GroceryLists

  @moduletag skip: "To reimplement"

  describe "grocery_lists" do
    alias Relaxir.GroceryLists.GroceryList

    @valid_attrs %{name: "some name", user_id: 1}
    @update_attrs %{name: "some updated name", user_id: 1}
    @invalid_attrs %{name: nil}

    def grocery_list_fixture(attrs \\ %{}) do
      {:ok, grocery_list} =
        attrs
        |> Enum.into(@valid_attrs)
        |> GroceryLists.create_grocery_list()

      grocery_list
    end

    def map_names(items) do
      Enum.map(items, fn i -> i.name end)
    end

    test "list_grocery_lists/0 returns all grocery_lists" do
      grocery_list = grocery_list_fixture()
      assert map_names(GroceryLists.list_grocery_lists()) == map_names([grocery_list])
    end

    test "get_grocery_list!/1 returns the grocery_list with given id" do
      grocery_list = grocery_list_fixture()
      assert GroceryLists.get_grocery_list!(grocery_list.id) == grocery_list
    end

    test "create_grocery_list/1 with valid data creates a grocery_list" do
      assert {:ok, %GroceryList{} = grocery_list} = GroceryLists.create_grocery_list(@valid_attrs)
      assert grocery_list.name == @valid_attrs.name
    end

    test "create_grocery_list/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GroceryLists.create_grocery_list(@invalid_attrs)
    end

    test "update_grocery_list/2 with valid data updates the grocery_list" do
      grocery_list = grocery_list_fixture()
      assert {:ok, %GroceryList{} = grocery_list} = GroceryLists.update_grocery_list(grocery_list, @update_attrs)
      assert grocery_list.name == @update_attrs.name
    end

    test "update_grocery_list/2 with invalid data returns error changeset" do
      grocery_list = grocery_list_fixture()
      assert {:error, %Ecto.Changeset{}} = GroceryLists.update_grocery_list(grocery_list, @invalid_attrs)
      assert grocery_list == GroceryLists.get_grocery_list!(grocery_list.id)
    end

    test "delete_grocery_list/1 deletes the grocery_list" do
      grocery_list = grocery_list_fixture()
      assert {:ok, %GroceryList{}} = GroceryLists.delete_grocery_list(grocery_list)
      assert_raise Ecto.NoResultsError, fn -> GroceryLists.get_grocery_list!(grocery_list.id) end
    end

    test "change_grocery_list/1 returns a grocery_list changeset" do
      grocery_list = grocery_list_fixture()
      assert %Ecto.Changeset{} = GroceryLists.change_grocery_list(grocery_list)
    end

    test "add_ingredient/2 adds an ingredient by id" do
      grocery_list = grocery_list_fixture()
      {:ok, ingredient} = Relaxir.Ingredients.create_ingredient(%{"name" => "F"})
      assert :ok = GroceryLists.add_ingredient(grocery_list, ingredient.id)
      assert hd(GroceryLists.get_grocery_list!(grocery_list.id).ingredient_grocery_lists).ingredient.name == ingredient.name
    end

    test "remove_ingredient/2 removes an ingredient by id" do
      grocery_list = grocery_list_fixture()
      {:ok, ingredient} = Relaxir.Ingredients.create_ingredient(%{"name" => "F"})
      GroceryLists.remove_ingredient(grocery_list, ingredient.id)
      assert GroceryLists.get_grocery_list!(grocery_list.id).ingredient_grocery_lists == []
    end
  end
end
