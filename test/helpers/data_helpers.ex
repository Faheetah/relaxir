defmodule Relaxir.DataHelpers do
  alias Relaxir.Categories
  alias Relaxir.Ingredients
  alias Relaxir.Recipes

  @ingredients %{
    ingredient: %{name: "ingredient"},
    ingredient_note: %{name: "ingredient_note", note: "ingredient_note note"},
    ingredient_amount: %{name: "ingredient_amount", amount: 2},
    ingredient_amount_fraction: %{name: "ingredient_amount_fraction", amount: 0.5},
    ingredient_amount_unit: %{name: "ingredient_amount_unit", amount: 0.25, unit: "cup"},
    ingredient_amount_units: %{name: "ingredient_amount_units", amount: 2.5, unit: "cups"},
    ingredient_amount_unit_note: %{name: "ingredient_amount_unit", amount: 1, unit: "cup", note: "ingredient_amount_unit note"},
    invalid_ingredient: %{name: nil},
    invalid_ingredient_unit_not_found: %{name: "invalid_ingredient_unit_not_found", amount: 1, unit: "invalid"},
    invalid_ingredient_unit_singular: %{name: "invalid_ingredient_unit_singular", amount: 50, unit: "cup"},
    invalid_ingredient_unit_plural: %{name: "invalid_ingredient_unit_plural", amount: 1, unit: "cups"}
  }

  @categories %{
    category1: %{name: "category1"},
    category2: %{name: "category2"}
  }

  @recipe %{
    "title" => "recipe",
    "directions" => "recipe directions"
  }

  @recipe_with_categories %{
    "title" => "recipe_with_categories",
    "directions" => "recipe with categories directions",
    "categories" => Enum.map(@categories, fn {_, c} -> c.name end)
  }

  @recipe_with_ingredients %{
    "title" => "recipe_with_ingredients",
    "directions" => "recipe with ingredients directions",
    "ingredients" => [
      @ingredients.ingredient,
      @ingredients.ingredient_note
    ]
  }

  def ingredients(_context) do
    %{ingredients: @ingredients}
  end

  def ingredient(_context) do
    fixture = %{name: "new ingredient"}
    {:ok, ingredient} = Ingredients.create_ingredient(fixture)
    %{ingredient: Map.put(ingredient, :fixture, fixture)}
  end

  def categories(_context) do
    %{categories: @categories}
  end

  def category(_context) do
    fixture = %{name: "new category"}
    {:ok, category} = Categories.create_category(fixture)
    %{category: Map.put(category, :fixture, fixture)}
  end

  def recipes(_context) do
    %{
      recipes: %{
        recipe: @recipe,
        recipe_with_categories: @recipe_with_categories,
        recipe_with_ingredients: @recipe_with_ingredients
      }
    }
  end

  def recipe(_context) do
    {:ok, recipe} = Recipes.create_recipe(@recipe)
    %{recipe: Map.put(recipe, :fixture, @recipe)}
  end

  def recipe_with_categories(_context) do
    {:ok, recipe} = Recipes.create_recipe(@recipe_with_categories)
    %{recipe_with_categories: Map.put(recipe, :fixture, @recipe_with_categories)}
  end

  def recipe_with_ingredients(_context) do
    {:ok, recipe} = Recipes.create_recipe(@recipe_with_ingredients)
    %{recipe_with_ingredients: Map.put(recipe, :fixture, @recipe_with_ingredients)}
  end
end
