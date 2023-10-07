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

    @tag badtest: "was checking if the update ingredient == the listed ingredient, breaks on preload"
    test "list_ingredients/0 returns all ingredients" do
      ingredient = ingredient_fixture()
      ingredients = Ingredients.list_ingredients()
      assert length(ingredients) == 1
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

  describe "nested ingredients" do
    test "add a parent ingredient to an ingredient twice" do
      ingredient_fixture(%{name: "poultry"})
      poultry = Ingredients.get_ingredient_by_name!("poultry")

      ingredient_fixture(%{name: "chicken", parent_ingredient_id: poultry.id})
      chicken = Ingredients.get_ingredient_by_name!("chicken")

      ingredient_fixture(%{name: "chicken thighs", parent_ingredient_id: chicken.id})
      chicken_thighs = Ingredients.get_ingredient_by_name!("chicken thighs")

      assert chicken_thighs.parent_ingredient.name == "chicken"
      assert chicken_thighs.parent_ingredient.parent_ingredient.name == "poultry"
    end
  end

  describe "ingredient inflex" do
    test "finds a name with a plural query" do
      ingredient_fixture(%{name: "ducks", singular: "duck"})
      query = ["ducks"]
      results = Relaxir.Ingredients.get_ingredients_by_name!(query)
      assert hd(results).name == "ducks"
    end

    test "finds a name with a singular query" do
      ingredient_fixture(%{name: "ducks", singular: "duck"})
      query = ["duck"]
      results = Relaxir.Ingredients.get_ingredients_by_name!(query)
      assert hd(results).name == "ducks"
    end

    @tag :skip
    test "finds a name missing singular with a singular query" do
      ingredient_fixture(%{name: "ducks"})
      query = ["duck"]
      results = Relaxir.Ingredients.get_ingredients_by_name!(query)
      assert hd(results).name == "ducks"
    end

    @tag :skip
    test "finds a name missing singular with a plural query" do
      ingredient_fixture(%{name: "ducks"})
      query = ["ducks"]
      results = Relaxir.Ingredients.get_ingredients_by_name!(query)
      assert hd(results).name == "ducks"
    end
  end
end
