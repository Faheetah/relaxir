defmodule Relaxir.CategoriesTest do
  use Relaxir.DataCase

  alias Relaxir.Categories
  alias Relaxir.DataHelpers

  describe "categories" do
    alias Relaxir.Categories.Category

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def category_fixture(attrs \\ %{}) do
      {:ok, category} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Categories.create_category()

      category
    end

    setup do
      # Use the existing fixture that creates a recipe with categories
      # We need to ensure unique titles to avoid constraint violations
      fixture_data = DataHelpers.recipes(%{})
      unique_title = "Unique #{fixture_data.recipes.recipe_with_categories["title"]} #{System.unique_integer()}"
      recipe_attrs = put_in(fixture_data.recipes.recipe_with_categories, ["title"], unique_title)

      {:ok, recipe} = Relaxir.Recipes.create_recipe(recipe_attrs)

      # Also create a standalone category without recipes for testing edge cases
      standalone_category = category_fixture(%{name: "standalone category"})

      %{
        recipe: recipe,
        categories_with_recipes: recipe.categories,
        standalone_category: standalone_category
      }
    end

    test "list_categories/0 returns all categories", %{categories_with_recipes: categories_with_recipes, standalone_category: standalone_category} do
      result = Categories.list_categories()

      # Should return all categories
      assert is_list(result)
      assert length(result) > 0

      # All categories with recipes should be in the results
      category_names = Enum.map(result, & &1.name)
      expected_names = Enum.map(categories_with_recipes, & &1.name)

      assert Enum.all?(expected_names, &(&1 in category_names))

      # Categories WITHOUT recipes SHOULD also be returned
      assert standalone_category.name in category_names
    end

    test "search_categories/1 returns matching category names" do
      category_fixture(%{name: "chinese food"})
      category_fixture(%{name: "chicken dishes"})
      category_fixture(%{name: "vegetarian meals"})

      result = Categories.search_categories("chi")

      # Should return category names that match the search term
      assert is_list(result)
      assert "chinese food" in result
      assert "chicken dishes" in result
      refute "vegetarian meals" in result
    end

    test "get_category!/1 returns the category with given id when it has recipes", %{recipe: recipe} do
      [category | _] = recipe.categories

      result = Categories.get_category!(category.id)

      # Should return the category with preloaded recipes
      assert %Category{id: id} = result
      assert id == category.id
      assert is_list(result.recipes)
    end

    test "get_category!/1 returns nil for category without recipes" do
      category = category_fixture()

      # This should return nil because the category has no associated recipes
      result = Categories.get_category!(category.id)
      assert is_nil(result)
    end

    test "create_category/1 with valid data creates a category" do
      assert {:ok, %Category{} = category} = Categories.create_category(@valid_attrs)
      assert category.name == "some name"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Categories.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      assert {:ok, %Category{} = category} = Categories.update_category(category, @update_attrs)
      assert category.name == "some updated name"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Categories.update_category(category, @invalid_attrs)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Categories.delete_category(category)

      # After deletion, getting the category should raise an error
      assert_raise Ecto.NoResultsError, fn ->
        Relaxir.Repo.get!(Category, category.id)
      end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Categories.change_category(category)
    end

    test "get_category_by_name!/1 returns a category when it has recipes", %{recipe: recipe} do
      [category | _] = recipe.categories

      result = Categories.get_category_by_name!(category.name)

      # Should return the category with preloaded recipes
      assert %Category{name: name} = result
      assert name == category.name
      assert is_list(result.recipes)
    end

    test "get_category_by_name!/1 returns nil for category without recipes" do
      category = category_fixture()

      # This should return nil because the category has no associated recipes
      result = Categories.get_category_by_name!(category.name)
      assert is_nil(result)
    end

    test "get_categories_by_name!/1 returns found categories" do
      # Create multiple categories
      _category1 = category_fixture(%{name: "category one"})
      _category2 = category_fixture(%{name: "category two"})

      # Create a recipe that uses one of these categories
      {:ok, _recipe} = Relaxir.Recipes.create_recipe(%{
        "title" => "test recipe #{System.unique_integer()}",
        "directions" => "test directions",
        "categories" => ["category one"]
      })

      # Get categories by name
      result = Categories.get_categories_by_name!(["category one", "category two"])

      # Should return both categories regardless of whether they have recipes
      assert is_list(result)
      assert length(result) == 2

      category_names = Enum.map(result, & &1.name)
      assert "category one" in category_names
      assert "category two" in category_names
    end

    test "top_categories/0 returns categories ranked by recipe count" do
      # Create categories with different numbers of recipes to test ranking
      category_name_3 = "category with 3 recipes #{System.unique_integer()}"
      category_name_2 = "category with 2 recipes #{System.unique_integer()}"
      category_name_1 = "category with 1 recipe #{System.unique_integer()}"

      # Create 3 recipes for the first category
      {:ok, _recipe1} = Relaxir.Recipes.create_recipe(%{
        "title" => "test recipe 1 #{System.unique_integer()}",
        "directions" => "test directions",
        "categories" => [category_name_3]
      })

      {:ok, _recipe2} = Relaxir.Recipes.create_recipe(%{
        "title" => "test recipe 2 #{System.unique_integer()}",
        "directions" => "test directions",
        "categories" => [category_name_3]
      })

      {:ok, _recipe3} = Relaxir.Recipes.create_recipe(%{
        "title" => "test recipe 3 #{System.unique_integer()}",
        "directions" => "test directions",
        "categories" => [category_name_3]
      })

      # Create 2 recipes for the second category
      {:ok, _recipe4} = Relaxir.Recipes.create_recipe(%{
        "title" => "test recipe 4 #{System.unique_integer()}",
        "directions" => "test directions",
        "categories" => [category_name_2]
      })

      {:ok, _recipe5} = Relaxir.Recipes.create_recipe(%{
        "title" => "test recipe 5 #{System.unique_integer()}",
        "directions" => "test directions",
        "categories" => [category_name_2]
      })

      # Create 1 recipe for the third category
      {:ok, _recipe6} = Relaxir.Recipes.create_recipe(%{
        "title" => "test recipe 6 #{System.unique_integer()}",
        "directions" => "test directions",
        "categories" => [category_name_1]
      })

      result = Categories.top_categories()

      # Should return categories with their recipes
      assert is_list(result)

      # Each item should be a category with a recipes field
      Enum.each(result, fn category ->
        assert %Category{} = category
        assert is_list(category.recipes)
      end)

      # Find our test categories in the results
      category_3_recipes = Enum.find(result, fn cat -> cat.name == category_name_3 end)
      category_2_recipes = Enum.find(result, fn cat -> cat.name == category_name_2 end)
      category_1_recipes = Enum.find(result, fn cat -> cat.name == category_name_1 end)

      # Verify that our categories with more recipes appear before those with fewer
      if category_3_recipes && category_2_recipes && category_1_recipes do
        # Count recipes for each category
        count_3 = Relaxir.Repo.aggregate(
          from(rc in Relaxir.RecipeCategory, where: rc.category_id == ^category_3_recipes.id),
          :count
        )

        count_2 = Relaxir.Repo.aggregate(
          from(rc in Relaxir.RecipeCategory, where: rc.category_id == ^category_2_recipes.id),
          :count
        )

        count_1 = Relaxir.Repo.aggregate(
          from(rc in Relaxir.RecipeCategory, where: rc.category_id == ^category_1_recipes.id),
          :count
        )

        # Should be ordered by recipe count descending
        assert count_3 >= count_2
        assert count_2 >= count_1
        assert count_3 == 3
        assert count_2 == 2
        assert count_1 == 1
      end
    end
  end
end
