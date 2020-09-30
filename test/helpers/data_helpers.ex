defmodule Relaxir.DataHelpers do
  alias Relaxir.Categories
  alias Relaxir.Ingredients
  alias Relaxir.Recipes

  @ingredients %{
    ingredient: %{name: "ingredient fixture"},
    ingredient_note: %{name: "ingredient_note fixture", note: "ingredient_note note"},
    ingredient_amount: %{name: "ingredient_amount fixture", amount: 2},
    ingredient_amount_fraction: %{name: "ingredient_amount_fraction fixture", amount: 0.5},
    ingredient_amount_unit: %{name: "ingredient_amount_unit fixture", amount: 0.25, unit: "cup"},
    ingredient_amount_units: %{name: "ingredient_amount_units fixture", amount: 2.5, unit: "cups"},
    ingredient_amount_unit_note: %{name: "ingredient_amount_unit fixture", amount: 1, unit: "cup", note: "ingredient_amount_unit note"},
    invalid_ingredient: %{name: nil},
    invalid_ingredient_unit_not_found: %{name: "invalid_ingredient_unit_not_found fixture", amount: 1, unit: "invalid"},
    invalid_ingredient_unit_singular: %{name: "invalid_ingredient_unit_singular fixture", amount: 50, unit: "cup"},
    invalid_ingredient_unit_plural: %{name: "invalid_ingredient_unit_plural fixture", amount: 1, unit: "cups"}
  }

  @categories %{
    category1: %{name: "category1 fixture"},
    category2: %{name: "category2 fixture"}
  }

  @recipe %{
    "title" => "draft recipe fixture",
    "directions" => "recipe directions fixture"
  }

  @recipe_published %{
    "title" => "published recipe fixture",
    "directions" => "published recipe directions fixture",
    "published" => true
  }

  @recipe_with_categories %{
    "title" => "recipe_with_categories fixture",
    "directions" => "recipe with categories directions fixture",
    "categories" => Enum.map(@categories, fn {_, c} -> c.name end)
  }

  @recipe_with_ingredients %{
    "title" => "recipe_with_ingredients fixture",
    "directions" => "recipe with ingredients directions fixture",
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
        recipe_published: @recipe_published,
        recipe_with_categories: @recipe_with_categories,
        recipe_with_ingredients: @recipe_with_ingredients
      }
    }
  end

  def recipe(_context) do
    {:ok, recipe} = Recipes.create_recipe(@recipe)
    %{recipe: Map.put(recipe, :fixture, @recipe)}
  end

  def recipe_published(_context) do
    {:ok, recipe} = Recipes.create_recipe(@recipe_published)
    %{recipe: Map.put(recipe, :fixture, @recipe_published)}
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
