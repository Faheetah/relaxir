defmodule Relaxir.IngredientsTest do
  use Relaxir.DataCase

  alias Relaxir.Ingredients

  describe "ingredients" do
    alias Relaxir.Ingredients.Ingredient

    @valid_attrs %{name: "some name", description: "some description"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def ingredient_fixture(attrs \\ %{}) do
      {:ok, ingredient} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Ingredients.create_ingredient()

      ingredient
    end

    test "list_ingredients/0 returns all ingredients" do
      ingredient = ingredient_fixture()
      assert Ingredients.list_ingredients() == [ingredient]
    end

    test "get_ingredient!/1 returns the ingredient with given id" do
      ingredient = ingredient_fixture()
      assert Ingredients.get_ingredient!(ingredient.id).name == @valid_attrs.name
    end

    test "create_ingredient/1 with valid data creates a ingredient" do
      assert {:ok, %Ingredient{} = ingredient} = Ingredients.create_ingredient(@valid_attrs)
      assert ingredient.name == "some name"
      assert ingredient.description == "some description"
    end

    test "create_ingredient/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ingredients.create_ingredient(@invalid_attrs)
    end

    test "update_ingredient/2 with valid data updates the ingredient" do
      ingredient = ingredient_fixture()

      assert {:ok, %Ingredient{} = ingredient} = Ingredients.update_ingredient(ingredient, @update_attrs)

      assert ingredient.name == "some updated name"
    end

    test "update_ingredient/2 with invalid data returns error changeset" do
      ingredient = ingredient_fixture()

      assert {:error, %Ecto.Changeset{}} = Ingredients.update_ingredient(ingredient, @invalid_attrs)

      assert Ingredients.get_ingredient!(ingredient.id).name == @valid_attrs.name
    end

    test "delete_ingredient/1 deletes the ingredient" do
      ingredient = ingredient_fixture()
      assert {:ok, %Ingredient{}} = Ingredients.delete_ingredient(ingredient)
      assert_raise Ecto.NoResultsError, fn -> Ingredients.get_ingredient!(ingredient.id) end
    end

    test "change_ingredient/1 returns a ingredient changeset" do
      ingredient = ingredient_fixture()
      assert %Ecto.Changeset{} = Ingredients.change_ingredient(ingredient)
    end

    test "get_ingredient_by_name!/1 returns a found ingredient" do
      ingredient_fixture()
      assert Ingredients.get_ingredient_by_name!("some name").name == @valid_attrs.name
    end

    test "get_ingredients_by_name!/1 returns found ingredients" do
      ingredient_fixture()
      assert hd(Ingredients.get_ingredients_by_name!(["some name"])).name == @valid_attrs.name
    end
  end
end
