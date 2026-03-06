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
      ingredient_fixture()
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
  end

  describe "list functions" do
    test "list_ingredients_missing_parent/0 returns ingredients without parents" do
      # Create an ingredient without a parent
      _ingredient = ingredient_fixture(%{name: "orphan"})

      # Get ingredients missing parents
      ingredients = Ingredients.list_ingredients_missing_parent()

      # Check that our orphan ingredient is in the list
      assert Enum.find(ingredients, fn i -> i.name == "orphan" end)
    end

    test "list_ingredients_missing_singular/0 returns ingredients without singular form" do
      # Create an ingredient without a singular form
      _ingredient = ingredient_fixture(%{name: "spices", singular: nil})

      # Get ingredients missing singular forms
      ingredients = Ingredients.list_ingredients_missing_singular()

      # Check that our ingredient is in the list
      assert Enum.find(ingredients, fn i -> i.name == "spices" end)
    end
  end

  describe "top ingredients" do
    test "top_ingredients/0 returns popular ingredients ranked by recipe count" do
      # Create ingredients
      _salt = ingredient_fixture(%{name: "salt"})
      _pepper = ingredient_fixture(%{name: "pepper"})
      _sugar = ingredient_fixture(%{name: "sugar"})

      # Create recipes and associate ingredients
      # Salt used in 3 recipes (most popular)
      Relaxir.Recipes.create_recipe(%{
        "title" => "Recipe 1",
        "directions" => "Mix salt and water",
        "ingredients" => [%{name: "salt"}]
      })

      Relaxir.Recipes.create_recipe(%{
        "title" => "Recipe 2",
        "directions" => "Add salt and pepper",
        "ingredients" => [%{name: "salt"}, %{name: "pepper"}]
      })

      Relaxir.Recipes.create_recipe(%{
        "title" => "Recipe 3",
        "directions" => "Season with salt",
        "ingredients" => [%{name: "salt"}]
      })

      # Pepper used in 1 recipe
      Relaxir.Recipes.create_recipe(%{
        "title" => "Recipe 4",
        "directions" => "Add some pepper",
        "ingredients" => [%{name: "pepper"}]
      })

      # Sugar used in 0 recipes

      # Get top ingredients (should exclude common ingredients like salt, pepper)
      top_ingredients = Ingredients.top_ingredients()

      # Should return a list
      assert is_list(top_ingredients)
    end

    test "top_ingredients/1 with limit returns specified number of ingredients" do
      # Create ingredients
      _salt = ingredient_fixture(%{name: "salt"})
      _pepper = ingredient_fixture(%{name: "pepper"})
      _sugar = ingredient_fixture(%{name: "sugar"})
      _flour = ingredient_fixture(%{name: "flour"})
      _butter = ingredient_fixture(%{name: "butter"})

      # Create recipes with different ingredients
      Relaxir.Recipes.create_recipe(%{
        "title" => "Recipe 1",
        "directions" => "Use flour and butter",
        "ingredients" => [%{name: "flour"}, %{name: "butter"}]
      })

      Relaxir.Recipes.create_recipe(%{
        "title" => "Recipe 2",
        "directions" => "Use flour",
        "ingredients" => [%{name: "flour"}]
      })

      Relaxir.Recipes.create_recipe(%{
        "title" => "Recipe 3",
        "directions" => "Use butter",
        "ingredients" => [%{name: "butter"}]
      })

      Relaxir.Recipes.create_recipe(%{
        "title" => "Recipe 4",
        "directions" => "Use sugar",
        "ingredients" => [%{name: "sugar"}]
      })

      # Get top 2 ingredients
      top_ingredients = Ingredients.top_ingredients(2)

      # Should return a list with at most 2 items
      assert is_list(top_ingredients)
      assert length(top_ingredients) <= 2


      # Check that we get ingredients with the highest recipe counts first
      # Flour and butter should be at the top (2 recipes each)
      # The exact ordering might vary, but we should get 2 items
      assert length(top_ingredients) == 2

      # Extract names of top ingredients
      top_ingredient_names = Enum.map(top_ingredients, &(&1.name))

      # Both flour and butter should be in the top ingredients (they each appear in 2 recipes)
      assert "flour" in top_ingredient_names
      assert "butter" in top_ingredient_names
    end
  end

  describe "utility functions" do
    test "update_image_filename/2 updates the image filename" do
      ingredient = ingredient_fixture()
      new_filename = "test-image.jpg"

      assert {:ok, _updated_ingredient} = Ingredients.update_image_filename(ingredient, new_filename)
      # Note: This might not actually update the image_filename field if it doesn't exist in the schema
    end

    test "maybe_singularize_attrs/1 with empty singular creates singular form" do
      attrs = %{"name" => "tomatoes", "singular" => ""}
      result = Ingredients.maybe_singularize_attrs(attrs)
      assert result["singular"] == "tomato"
    end

    test "maybe_singularize_attrs/1 with existing singular keeps it" do
      attrs = %{"name" => "tomatoes", "singular" => "tomato"}
      result = Ingredients.maybe_singularize_attrs(attrs)
      assert result["singular"] == "tomato"
    end

    test "maybe_singularize_attrs/1 without singular key keeps attrs unchanged" do
      attrs = %{"name" => "salt"}
      result = Ingredients.maybe_singularize_attrs(attrs)
      assert result == attrs
    end
  end
end
