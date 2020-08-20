defmodule Relaxir.RecipesTest do
  use Relaxir.DataCase

  alias Relaxir.Recipes
  alias Relaxir.Ingredients

  describe "recipes" do
    alias Relaxir.Recipes.Recipe

    @valid_attrs %{
      "directions" => "some directions", 
      "title" => "some title", 
      "categories" => [], 
      "recipe_ingredients" => []
    }

    @update_attrs %{
      "directions" => "some updated directions", 
      "title" => "some updated title",
      "categories" => [], 
      "recipe_ingredients" => []
    }

    @invalid_attrs %{
      "directions" => nil, 
      "title" => nil,
      "categories" => [], 
      "recipe_ingredients" => []
    }

    @ingredients [
      %{"ingredient" => %{"name" => "cauliflower"}},
      %{"ingredient" => %{"name" => "broccoli"}},
    ]

    def recipe_fixture(attrs \\ %{}) do
      {:ok, recipe} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Recipes.create_recipe()

      recipe
      |> Repo.preload(:ingredients)
    end

    test "list_recipes/0 returns all recipes" do
      Recipes.create_recipe(@valid_attrs)
      Recipes.create_recipe(@update_attrs)
      recipes = Recipes.list_recipes()
      assert length(recipes) == 2
      assert Enum.sort([@valid_attrs["title"], @update_attrs["title"]]) == Enum.sort(Enum.map(recipes, fn r -> r.title end))
    end

    test "get_recipe!/1 returns the recipe with given id" do
      recipe = recipe_fixture()
      assert Recipes.get_recipe!(recipe.id) == recipe
    end

    test "create_recipe/1 with valid data creates a recipe" do
      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(@valid_attrs)
      assert recipe.directions == "some directions"
      assert recipe.title == "some title"
    end

    test "create_recipe/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Recipes.create_recipe(@invalid_attrs)
    end

    test "update_recipe/2 with valid data updates the recipe" do
      recipe = recipe_fixture()
      assert {:ok, %Recipe{} = recipe} = Recipes.update_recipe(recipe, @update_attrs)
      assert recipe.directions == "some updated directions"
      assert recipe.title == "some updated title"
    end

    test "update_recipe/2 with invalid data returns error changeset" do
      recipe = recipe_fixture()
      assert {:error, %Ecto.Changeset{}} = Recipes.update_recipe(recipe, @invalid_attrs)
      assert recipe == Recipes.get_recipe!(recipe.id)
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

    test "create_recipe/1 includes ingredients" do
      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(%{@valid_attrs | "recipe_ingredients" => @ingredients})
      assert ["cauliflower", "broccoli"] == recipe.recipe_ingredients
      |> Enum.map(fn i -> i.ingredient.name end)
    end

    test "update_recipe/2 adds new ingredients" do
      {:ok, %Recipe{} = recipe} = Recipes.create_recipe(%{@valid_attrs | "recipe_ingredients" => @ingredients})
      existing_ingredients = recipe.recipe_ingredients
      |> Enum.map(fn i -> %{
          "id" => i.id,
          "ingredient" => %{
            "name" => i.ingredient.name, "id" => i.ingredient.id
          }
        } end)

      recipe_ingredients = %{
        "recipe_ingredients" => existing_ingredients ++ [
          %{"ingredient" => %{"name" => "kale"}}
        ],
        "categories" => []
      }

      {:ok, %Recipe{} = updated_recipe} = Recipes.update_recipe(recipe, recipe_ingredients)

      ingredients = updated_recipe.recipe_ingredients
      |> Enum.map(fn i -> i.ingredient.name end)

      assert length(["kale", "cauliflower", "broccoli"] -- ingredients)
    end

    test "update_recipe/2 retains existing ingredients" do
      {:ok, %Recipe{} = recipe} = Recipes.create_recipe(%{@valid_attrs | "recipe_ingredients" => @ingredients})
      existing_ingredients = recipe.recipe_ingredients
      |> Enum.map(fn i -> %{
          "id" => i.id,
          "ingredient" => %{
            "name" => i.ingredient.name, "id" => i.ingredient.id
          }
        } end)

      {:ok, new_ingredient} = Ingredients.create_ingredient(%{"name" => "kohlrabi"})

      recipe_ingredients = %{
        "recipe_ingredients" => existing_ingredients ++ [
          %{"recipe_id" => recipe.id, "ingredient_id" => new_ingredient.id}
        ],
        "categories" => []
      }

      Recipes.update_recipe(recipe, recipe_ingredients)

      recipe = Recipes.get_recipe!(recipe.id)
      ingredients = recipe.recipe_ingredients
      |> Enum.map(fn i -> i.ingredient.name end)

      assert length(["kohlrabi", "cauliflower", "broccoli"] -- ingredients)
    end

    test "update_recipe/2 removes ingredients" do
    end
  end
end
