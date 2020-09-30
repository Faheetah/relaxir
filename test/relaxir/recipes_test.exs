defmodule Relaxir.RecipesTest do
  use Relaxir.DataCase

  alias Relaxir.Recipes
  alias Relaxir.Ingredients
  alias Relaxir.Units
  alias Relaxir.Categories

  describe "list_recipes/0" do
    setup [:recipe, :recipe_with_ingredients]

    test "returns all recipes", %{recipe: recipe, recipe_with_ingredients: recipe_with_ingredients} do
      recipes =
        Recipes.list_recipes()
        |> Enum.map(fn r -> r.title end)
        |> Enum.into(MapSet.new())

      attrs =
        [recipe, recipe_with_ingredients]
        |> Enum.map(fn r -> r.fixture["title"] end)
        |> Enum.into(MapSet.new())

      assert MapSet.intersection(recipes, attrs)
    end

    test "returns all published recipes" do
      Recipes.create_recipe(%{"title" => "not published"})
      Recipes.create_recipe(%{"title" => "published", "published" => true})

      assert length(Recipes.list_published_recipes()) == 1
    end
  end

  describe "get_recipe/1" do
    setup [:recipe]

    test "returns the recipe with given id", %{recipe: recipe} do
      assert Recipes.get_recipe!(recipe.id).title == recipe.fixture["title"]
    end
  end

  describe "create_recipe/1" do
    setup [:ingredients]

    test "create_recipe/1 with valid data creates a recipe" do
      attrs = %{"title" => "title", "directions" => "directions"}
      {:ok, recipe} = Recipes.create_recipe(attrs)
      assert recipe.title == attrs["title"]
      assert recipe.directions == attrs["directions"]
    end

    test "create_recipe/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Recipes.create_recipe(%{})
    end

    test "create_recipe/1 with invalid recipe_ingredients returns error changeset", %{ingredients: ingredients} do
      ingredient = ingredients.ingredient
      attrs = %{"title" => "title", "recipe_ingredients" => [%{ingredient: ingredient}, %{ingredient: ingredient}]}
      assert {:error, %Ecto.Changeset{}} = Recipes.create_recipe(attrs)
    end

    test "create_recipe/1 includes ingredients", %{ingredients: ingredients} do
      ingredient = ingredients.ingredient
      attrs = %{"title" => "title", "recipe_ingredients" => [%{ingredient: ingredient}]}
      {:ok, recipe} = Recipes.create_recipe(attrs)

      assert [ingredient.name] ==
               recipe.recipe_ingredients
               |> Enum.map(fn i -> i.ingredient.name end)
    end
  end

  describe "update_recipe/2" do
    setup [:recipe, :recipe_with_ingredients]

    test "with valid data updates the recipe", %{recipe: recipe} do
      attrs = %{"title" => "updated title", "directions" => "updated directions"}
      {:ok, recipe} = Recipes.update_recipe(recipe, attrs)
      assert recipe.directions == attrs["directions"]
      assert recipe.title == attrs["title"]
    end

    test "with invalid data returns error changeset", %{recipe: recipe} do
      attrs = %{"title" => nil}
      assert {:error, recipe} = Recipes.update_recipe(recipe, attrs)
    end

    test "adds new ingredients", %{recipe: recipe} do
      new_ingredient = "new ingredient"

      existing_ingredients =
        recipe.recipe_ingredients
        |> Enum.map(fn i -> %{name: i.ingredient["name"]} end)

      attrs = %{"ingredients" => [%{name: new_ingredient} | existing_ingredients]}

      {:ok, recipe} = Recipes.update_recipe(recipe, attrs)

      assert "new ingredient" in Enum.map(recipe.recipe_ingredients, fn i -> i.ingredient.name end)
    end

    test "retains existing ingredients", %{recipe_with_ingredients: recipe_with_ingredients} do
      existing_ingredients =
        recipe_with_ingredients.recipe_ingredients
        |> Enum.map(fn i -> %{name: i.ingredient.name} end)

      attrs = %{"ingredients" => [%{name: "_"} | existing_ingredients]}

      {:ok, recipe} = Recipes.update_recipe(recipe_with_ingredients, attrs)

      ingredients =
        recipe.recipe_ingredients
        |> Enum.map(fn i -> i.ingredient.name end)
        |> Enum.into(MapSet.new())

      assert existing_ingredients
             |> Enum.map(fn i -> i.name end)
             |> Enum.into(MapSet.new())
             |> MapSet.intersection(ingredients)
    end

    test "removes ingredients", %{recipe_with_ingredients: recipe_with_ingredients} do
      Recipes.update_recipe(recipe_with_ingredients, %{"ingredients" => []})

      recipe = Recipes.get_recipe!(recipe_with_ingredients.id)
      Relaxir.Ingredients.list_ingredients()

      assert recipe.recipe_ingredients == []
      # Ensure only the RecipeIngredient link was removed, do not cascade delete to ingredients
      assert length(Relaxir.Ingredients.list_ingredients()) > 0
    end
  end

  describe "delete_recipe/1 recipes" do
    setup [:recipe]

    test "deletes the recipe", %{recipe: recipe} do
      assert {:ok, _} = Recipes.delete_recipe(recipe)
      assert_raise Ecto.NoResultsError, fn -> Recipes.get_recipe!(recipe.id) end
    end
  end

  describe "change_recipe/1" do
    setup [:recipe]

    test "returns a recipe changeset", %{recipe: recipe} do
      assert %Ecto.Changeset{} = Recipes.change_recipe(recipe)
    end
  end

  describe "map_ingredients/1" do
    setup [:ingredients]

    test "generates a new ingredient", %{ingredients: ingredients} do
      ingredient = ingredients.ingredient

      ingredients =
        %{"ingredients" => [ingredients.ingredient]}
        |> Ingredients.Parser.map_ingredients()
        |> Map.get("recipe_ingredients")
        |> Enum.map(fn i -> i.ingredient.name end)

      assert ingredient.name in ingredients
    end

    test "finds an existing ingredient", %{ingredients: ingredients} do
      ingredient = ingredients.ingredient
      {:ok, new_ingredient} = Ingredients.create_ingredient(ingredient)

      ingredients =
        %{"ingredients" => [ingredient]}
        |> Ingredients.Parser.map_ingredients()
        |> Map.get("recipe_ingredients")
        |> Enum.map(fn i -> i.ingredient_id end)

      assert new_ingredient.id in ingredients
    end

    test "adds a note to an ingredient", %{ingredients: ingredients} do
      ingredient = ingredients.ingredient
      ingredients =
        %{"ingredients" => [Map.merge(ingredient, %{note: "drained"})]}
        |> Ingredients.Parser.map_ingredients()
        |> Map.get("recipe_ingredients")

      assert hd(ingredients).ingredient.note == "drained"
    end

    test "adds an amount and unit to an ingredient", %{ingredients: ingredients} do
      ingredient = ingredients.ingredient
      {:ok, unit} = Units.create_unit(%{name: "ton"})

      ingredients =
        %{"ingredients" => [Map.merge(ingredient, %{amount: 2, unit: "tons"})]}
        |> Ingredients.Parser.map_ingredients()
        |> Map.get("recipe_ingredients")

      assert hd(ingredients).amount == 2
      assert hd(ingredients).unit_id == unit.id
    end

    test "adds an amount to a found ingredient when no unit specified" do
      recipe_ingredient =
        %{"ingredients" => [%{name: "second", unit: "first", amount: 1}]}
        |> Ingredients.Parser.map_ingredients()
        |> Map.get("recipe_ingredients")
        |> hd

      assert recipe_ingredient.amount == 1
      assert recipe_ingredient.ingredient.name == "first second"
    end

    test "creates a recipe using mapped units", %{ingredients: ingredients} do
      ingredient = ingredients.ingredient_amount_unit_note
      assert {:ok, recipe} = Recipes.create_recipe(%{"title" => "_", "ingredients" => [ingredient]})
      recipe_ingredient = hd(recipe.recipe_ingredients)

      assert recipe_ingredient.ingredient.name == ingredient.name
      assert recipe_ingredient.amount == ingredient.amount
      assert Inflex.singularize(recipe_ingredient.unit.name) == ingredient.unit
      assert recipe_ingredient.note == ingredient.note
    end
  end

  describe "parsing categories" do
    test "builds a list of new categories when it doesn't find an category" do
      attrs = %{"categories" => ["texmex", "breakfast"]}
      assert %{category: %{name: "texmex"}} in Categories.Parser.map_categories(attrs)["recipe_categories"]
    end

    test "finds existing categories" do
      {:ok, texmex} = Categories.create_category(%{name: "texmex"})

      attrs = %{"categories" => ["texmex", "italian"]}
      assert %{category_id: texmex.id} in Categories.Parser.map_categories(attrs)["recipe_categories"]
    end
  end
end
