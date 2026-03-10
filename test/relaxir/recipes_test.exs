defmodule Relaxir.RecipesTest do
  use Relaxir.DataCase

  alias Relaxir.Recipes
  alias Relaxir.Recipes.Recipe

  describe "recipes" do
    @valid_attrs %{
      "title" => "some title",
      "directions" => "some directions"
    }
    @update_attrs %{
      "title" => "some updated title #{System.unique_integer()}"
    }
    @invalid_attrs %{
      "title" => nil
    }

    def recipe_fixture(attrs \\ %{}) do
      # Ensure unique titles to avoid constraint violations
      unique_title = "some title #{System.unique_integer()}"
      merged_attrs = Map.merge(@valid_attrs, attrs)
      merged_attrs = Map.put(merged_attrs, "title", unique_title)
      {:ok, recipe} = Recipes.create_recipe(merged_attrs)
      recipe
    end

    test "list_recipes/1 returns all recipes for current user" do
      # Create two specific recipes for this test
      recipe1 = recipe_fixture(%{"published" => true})
      recipe2 = recipe_fixture(%{"published" => false})

      # When current_user? is true, should return all recipes (including both we created)
      all_recipes = Recipes.list_recipes(true)
      recipe_ids = Enum.map(all_recipes, & &1.id)
      assert recipe1.id in recipe_ids
      assert recipe2.id in recipe_ids

      # When current_user? is false, should return only published recipes
      published_recipes = Recipes.list_recipes(false)
      published_recipe_ids = Enum.map(published_recipes, & &1.id)
      assert recipe1.id in published_recipe_ids
      refute recipe2.id in published_recipe_ids
    end

    test "get_recipe!/1 returns the recipe with given id" do
      recipe = recipe_fixture()
      fetched_recipe = Recipes.get_recipe!(recipe.id)
      assert fetched_recipe.title == recipe.title
      assert fetched_recipe.directions == recipe.directions
    end

    test "get_recipe_by_name!/1 returns the recipe with given title" do
      recipe = recipe_fixture()
      fetched_recipe = Recipes.get_recipe_by_name!(recipe.title)
      assert fetched_recipe.title == recipe.title
    end

    test "create_recipe/1 with valid data creates a recipe" do
      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(@valid_attrs)
      assert recipe.title == "some title"
      assert recipe.directions == "some directions"
    end

    test "create_recipe/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Recipes.create_recipe(@invalid_attrs)
    end

    test "update_recipe/2 with valid data updates the recipe" do
      recipe = recipe_fixture()
      assert {:ok, %Recipe{} = updated_recipe} = Recipes.update_recipe(recipe, @update_attrs)
      assert updated_recipe.title == @update_attrs["title"]
    end

    test "update_recipe/2 with invalid data returns error changeset" do
      recipe = recipe_fixture()
      assert {:error, %Ecto.Changeset{}} = Recipes.update_recipe(recipe, @invalid_attrs)
      fetched_recipe = Recipes.get_recipe!(recipe.id)
      assert fetched_recipe.title == recipe.title
    end

    test "delete_recipe/1 deletes the recipe" do
      recipe = recipe_fixture()
      assert {:ok, %Recipe{}} = Recipes.delete_recipe(recipe)
      assert_raise Ecto.NoResultsError, fn -> Recipes.get_recipe!(recipe.id) end
    end

    test "change_recipe/1 returns a recipe changeset" do
      recipe = recipe_fixture()
      assert %Ecto.Changeset{} = Recipes.change_recipe(recipe)
    end

    test "update_image_filename/2 updates the image filename" do
      recipe = recipe_fixture()
      new_filename = "test-image.jpg"
      assert {:ok, updated_recipe} = Recipes.update_image_filename(recipe, new_filename)
      assert updated_recipe.image_filename == new_filename
    end

    test "create_recipe/1 with various recipe_ingredients permutations" do
      unique_title = "Recipe with ingredient permutations #{System.unique_integer()}"

      # Test various permutations of "amount|unit|ingredient|note"
      attrs = %{
        "title" => unique_title,
        "directions" => "Test directions",
        "recipe_ingredients" => [
          # All fields present
          "2.5|c|flour|sifted",
          # Missing amount (empty)
          "|c|flour2|sifted2",
          # Missing unit (empty)
          "3.0||flour3|sifted3",
          # Missing note (empty)
          "1.5|c|flour4|",
          # No amount, no unit
          "||flour5|to taste",
          # No amount, no note
          "|tbsp|flour6|",
          # No unit, no note
          "2.0||flour7|",
          # Only ingredient
          "||flour8|",
          # Decimal amount
          "0.5|c|flour9|finely ground",
          # Whole number amount
          "1|c|flour10|"
        ]
      }

      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(attrs)
      assert recipe.title == unique_title

      # Check that recipe ingredients were created
      assert Enum.count(recipe.recipe_ingredients) == 10

      # Verify specific ingredients with different permutations
      # Find flour with amount 2.5, unit cup, note sifted
      flour1 = Enum.find(recipe.recipe_ingredients, fn ri ->
        ri.ingredient.name == "flour" and ri.amount == 2.5 and
        ri.unit.name == "cup" and ri.note == "sifted"
      end)
      assert flour1, "Expected to find flour with amount 2.5, unit cup, note sifted"

      # Find flour2 with nil amount, unit cup, note sifted2
      flour2 = Enum.find(recipe.recipe_ingredients, fn ri ->
        ri.ingredient.name == "flour2" and is_nil(ri.amount) and
        ri.unit.name == "cup" and ri.note == "sifted2"
      end)
      assert flour2, "Expected to find flour2 with nil amount, unit cup, note sifted2"

      # Find flour3 with amount 3.0, nil unit, note sifted3
      flour3 = Enum.find(recipe.recipe_ingredients, fn ri ->
        ri.ingredient.name == "flour3" and ri.amount == 3.0 and
        is_nil(ri.unit) and ri.note == "sifted3"
      end)
      assert flour3, "Expected to find flour3 with amount 3.0, nil unit, note sifted3"

      # Find flour4 with amount 1.5, unit cup, empty note
      flour4 = Enum.find(recipe.recipe_ingredients, fn ri ->
        ri.ingredient.name == "flour4" and ri.amount == 1.5 and
        ri.unit.name == "cup" and ri.note == ""
      end)
      assert flour4, "Expected to find flour4 with amount 1.5, unit cup, empty note"

      # Find flour5 with nil amount, nil unit, note "to taste"
      flour5 = Enum.find(recipe.recipe_ingredients, fn ri ->
        ri.ingredient.name == "flour5" and is_nil(ri.amount) and
        is_nil(ri.unit) and ri.note == "to taste"
      end)
      assert flour5, "Expected to find flour5 with nil amount, nil unit, note 'to taste'"

      # Find flour6 with nil amount, unit tbsp, empty note
      flour6 = Enum.find(recipe.recipe_ingredients, fn ri ->
        ri.ingredient.name == "flour6" and is_nil(ri.amount) and
        ri.unit.name == "tablespoon" and ri.note == ""
      end)
      assert flour6, "Expected to find flour6 with nil amount, unit tablespoon, empty note"

      # Find flour7 with amount 2.0, nil unit, empty note
      flour7 = Enum.find(recipe.recipe_ingredients, fn ri ->
        ri.ingredient.name == "flour7" and ri.amount == 2.0 and
        is_nil(ri.unit) and ri.note == ""
      end)
      assert flour7, "Expected to find flour7 with amount 2.0, nil unit, empty note"

      # Find flour8 with nil amount, nil unit, empty note
      flour8 = Enum.find(recipe.recipe_ingredients, fn ri ->
        ri.ingredient.name == "flour8" and is_nil(ri.amount) and
        is_nil(ri.unit) and ri.note == ""
      end)
      assert flour8, "Expected to find flour8 with nil amount, nil unit, empty note"

      # Find flour9 with decimal amount 0.5, unit cup, note "finely ground"
      flour9 = Enum.find(recipe.recipe_ingredients, fn ri ->
        ri.ingredient.name == "flour9" and ri.amount == 0.5 and
        ri.unit.name == "cup" and ri.note == "finely ground"
      end)
      assert flour9, "Expected to find flour9 with amount 0.5, unit cup, note 'finely ground'"

      # Find flour10 with whole number amount 1, unit cup, empty note
      flour10 = Enum.find(recipe.recipe_ingredients, fn ri ->
        ri.ingredient.name == "flour10" and ri.amount == 1.0 and
        ri.unit.name == "cup" and ri.note == ""
      end)
      assert flour10, "Expected to find flour10 with amount 1.0, unit cup, empty note"
    end
  end

  describe "recipes with categories" do
    test "create_recipe/1 with categories creates recipe and associates categories" do
      unique_title = "Recipe with categories #{System.unique_integer()}"
      attrs = %{
        "title" => unique_title,
        "directions" => "Test directions",
        "categories" => ["dessert", "sweet"]
      }

      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(attrs)
      assert recipe.title == unique_title

      # Check that categories were created and associated
      assert Enum.count(recipe.categories) == 2
      category_names = Enum.map(recipe.categories, & &1.name)
      assert "dessert" in category_names
      assert "sweet" in category_names
    end

    test "update_recipe/2 with categories updates recipe and modifies category associations" do
      # Create a recipe with categories
      unique_title = "Recipe with categories #{System.unique_integer()}"
      attrs = %{
        "title" => unique_title,
        "directions" => "Test directions",
        "categories" => ["dessert", "sweet"]
      }

      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(attrs)

      # Verify initial categories
      assert Enum.count(recipe.categories) == 2
      category_names = Enum.map(recipe.categories, & &1.name)
      assert "dessert" in category_names
      assert "sweet" in category_names

      # Update recipe with different categories
      update_attrs = %{
        "title" => recipe.title,
        "directions" => recipe.directions,
        "categories" => ["savory", "main course"]
      }

      assert {:ok, %Recipe{} = updated_recipe} = Recipes.update_recipe(recipe, update_attrs)

      # Verify updated categories
      assert Enum.count(updated_recipe.categories) == 2
      updated_category_names = Enum.map(updated_recipe.categories, & &1.name)
      assert "savory" in updated_category_names
      assert "main course" in updated_category_names
      refute "dessert" in updated_category_names
      refute "sweet" in updated_category_names
    end

    test "update_recipe/2 removes all categories when empty categories list provided" do
      # Create a recipe with categories
      unique_title = "Recipe with categories #{System.unique_integer()}"
      attrs = %{
        "title" => unique_title,
        "directions" => "Test directions",
        "categories" => ["dessert", "sweet"]
      }

      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(attrs)

      # Verify initial categories
      assert Enum.count(recipe.categories) == 2

      # Update recipe with empty categories list
      update_attrs = %{
        "title" => recipe.title,
        "directions" => recipe.directions,
        "categories" => []
      }

      assert {:ok, %Recipe{} = updated_recipe} = Recipes.update_recipe(recipe, update_attrs)

      # Verify all categories are removed
      assert updated_recipe.categories == []
    end
  end

  describe "recipes with ingredients" do
    test "create_recipe/1 with recipe_ingredients creates recipe and associates ingredients" do
      unique_title = "Recipe with ingredients #{System.unique_integer()}"
      attrs = %{
        "title" => unique_title,
        "directions" => "Test directions",
        "recipe_ingredients" => ["2.5|c|flour|sifted", "1|tbsp|butter|melted"]
      }

      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(attrs)
      assert recipe.title == unique_title

      # Check that recipe ingredients were created
      assert Enum.count(recipe.recipe_ingredients) == 2

      # Verify first ingredient
      first_ri = Enum.find(recipe.recipe_ingredients, fn ri -> ri.ingredient.name == "flour" end)
      assert first_ri.amount == 2.5
      assert first_ri.unit.name == "cup"
      assert first_ri.note == "sifted"

      # Verify second ingredient
      second_ri = Enum.find(recipe.recipe_ingredients, fn ri -> ri.ingredient.name == "butter" end)
      assert second_ri.amount == 1.0
      assert second_ri.unit.name == "tablespoon"
      assert second_ri.note == "melted"
    end

    test "update_recipe/2 with recipe_ingredients updates recipe and modifies ingredient associations" do
      # Create a recipe with ingredients
      unique_title = "Recipe with ingredients #{System.unique_integer()}"
      attrs = %{
        "title" => unique_title,
        "directions" => "Test directions",
        "recipe_ingredients" => ["2.5|c|flour|sifted", "1|tbsp|butter|melted"]
      }

      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(attrs)

      # Verify initial ingredients with amounts, units, and notes
      assert Enum.count(recipe.recipe_ingredients) == 2

      # Verify first ingredient
      first_ri = Enum.find(recipe.recipe_ingredients, fn ri -> ri.ingredient.name == "flour" end)
      assert first_ri.amount == 2.5
      assert first_ri.unit.name == "cup"
      assert first_ri.note == "sifted"

      # Verify second ingredient
      second_ri = Enum.find(recipe.recipe_ingredients, fn ri -> ri.ingredient.name == "butter" end)
      assert second_ri.amount == 1.0
      assert second_ri.unit.name == "tablespoon"
      assert second_ri.note == "melted"

      # Update recipe with different ingredients
      update_attrs = %{
        "title" => recipe.title,
        "directions" => recipe.directions,
        "recipe_ingredients" => ["1.5|c|sugar|granulated", "3|whole|eggs|large", "0.5|c|milk|whole"]
      }

      assert {:ok, %Recipe{} = updated_recipe} = Recipes.update_recipe(recipe, update_attrs)

      # Verify updated ingredients with amounts, units, and notes
      assert Enum.count(updated_recipe.recipe_ingredients) == 3

      # Verify first updated ingredient
      first_updated_ri = Enum.find(updated_recipe.recipe_ingredients, fn ri -> ri.ingredient.name == "sugar" end)
      assert first_updated_ri.amount == 1.5
      assert first_updated_ri.unit.name == "cup"
      assert first_updated_ri.note == "granulated"

      # Verify second updated ingredient
      second_updated_ri = Enum.find(updated_recipe.recipe_ingredients, fn ri -> ri.ingredient.name == "eggs" end)
      assert second_updated_ri.amount == 3.0
      assert second_updated_ri.unit.name == "whole"
      assert second_updated_ri.note == "large"

      # Verify third updated ingredient
      third_updated_ri = Enum.find(updated_recipe.recipe_ingredients, fn ri -> ri.ingredient.name == "milk" end)
      assert third_updated_ri.amount == 0.5
      assert third_updated_ri.unit.name == "cup"
      assert third_updated_ri.note == "whole"

      # Verify old ingredients are removed
      updated_ingredient_names = Enum.map(updated_recipe.recipe_ingredients, & &1.ingredient.name)
      refute "flour" in updated_ingredient_names
      refute "butter" in updated_ingredient_names
    end

    test "update_recipe/2 removes all ingredients when empty recipe_ingredients list provided" do
      # Create a recipe with ingredients
      unique_title = "Recipe with ingredients #{System.unique_integer()}"
      attrs = %{
        "title" => unique_title,
        "directions" => "Test directions",
        "recipe_ingredients" => ["||flour|", "||butter|"]
      }

      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(attrs)

      # Verify initial ingredients
      assert Enum.count(recipe.recipe_ingredients) == 2

      # Update recipe with empty ingredients list
      update_attrs = %{
        "title" => recipe.title,
        "directions" => recipe.directions,
        "recipe_ingredients" => []
      }

      assert {:ok, %Recipe{} = updated_recipe} = Recipes.update_recipe(recipe, update_attrs)

      # Verify all ingredients are removed
      assert updated_recipe.recipe_ingredients == []
    end
  end
end
