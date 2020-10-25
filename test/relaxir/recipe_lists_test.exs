defmodule Relaxir.RecipeListsTest do
  use Relaxir.DataCase

  alias Relaxir.RecipeLists

  describe "recipe_list" do
    alias Relaxir.RecipeLists.RecipeList

    @valid_attrs %{name: "some name", user_id: 1}
    @update_attrs %{name: "some updated name", user_id: 1}
    @invalid_attrs %{name: nil}

    def recipe_list_fixture(attrs \\ %{}) do
      {:ok, recipe_list} =
        attrs
        |> Enum.into(@valid_attrs)
        |> RecipeLists.create_recipe_list()

      recipe_list
    end

    def map_names(items) do
      Enum.map(items, fn i -> i.name end)
    end

    test "list_recipe_lists/0 returns all recipe_list" do
      recipe_list = recipe_list_fixture()
      assert map_names(RecipeLists.list_recipe_lists()) == map_names([recipe_list])
    end

    test "get_recipe_list!/1 returns the recipe_list with given id" do
      recipe_list = recipe_list_fixture()
      assert RecipeLists.get_recipe_list!(recipe_list.id) == recipe_list
    end

    test "create_recipe_list/1 with valid data creates a recipe_list" do
      assert {:ok, %RecipeList{} = recipe_list} = RecipeLists.create_recipe_list(@valid_attrs)
      assert recipe_list.name == @valid_attrs.name
    end

    test "create_recipe_list/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = RecipeLists.create_recipe_list(@invalid_attrs)
    end

    test "update_recipe_list/2 with valid data updates the recipe_list" do
      recipe_list = recipe_list_fixture()
      assert {:ok, %RecipeList{} = recipe_list} = RecipeLists.update_recipe_list(recipe_list, @update_attrs)
      assert recipe_list.name == @update_attrs.name
    end

    test "update_recipe_list/2 with invalid data returns error changeset" do
      recipe_list = recipe_list_fixture()
      assert {:error, %Ecto.Changeset{}} = RecipeLists.update_recipe_list(recipe_list, @invalid_attrs)
      assert recipe_list == RecipeLists.get_recipe_list!(recipe_list.id)
    end

    test "delete_recipe_list/1 deletes the recipe_list" do
      recipe_list = recipe_list_fixture()
      assert {:ok, %RecipeList{}} = RecipeLists.delete_recipe_list(recipe_list)
      assert_raise Ecto.NoResultsError, fn -> RecipeLists.get_recipe_list!(recipe_list.id) end
    end

    test "change_recipe_list/1 returns a recipe_list changeset" do
      recipe_list = recipe_list_fixture()
      assert %Ecto.Changeset{} = RecipeLists.change_recipe_list(recipe_list)
    end

    test "add_recipe/2 adds a recipe by id" do
      recipe_list = recipe_list_fixture()
      {:ok, recipe} = Relaxir.Recipes.create_recipe(%{"title" => "F"})
      assert :ok = RecipeLists.add_recipe(recipe_list, recipe.id)
      assert hd(RecipeLists.get_recipe_list!(recipe_list.id).recipe_recipe_lists).recipe.title == recipe.title
    end

    test "remove_recipe/2 removes a recipe by id" do
      recipe_list = recipe_list_fixture()
      {:ok, recipe} = Relaxir.Recipes.create_recipe(%{"title" => "F"})
      RecipeLists.remove_recipe(recipe_list, recipe.id)
      assert RecipeLists.get_recipe_list!(recipe_list.id).recipe_recipe_lists == []
    end
  end
end
