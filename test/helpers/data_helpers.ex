defmodule Relaxir.DataHelpers do
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

  @recipe %{
    "title" => "recipe",
    "directions" => "recipe directions"
  }

  @recipe_with_categories %{
    "title" => "recipe_with_categories",
    "directions" => "recipe with categories directions",
    "categories" => ["category1", "category2"]
  }

  @recipe_with_ingredients %{
    "title" => "recipe_with_ingredients",
    "directions" => "recipe with ingredients directions",
    "ingredients" => [
      @ingredients.ingredient,
      @ingredients.ingredient_note
    ]
  }

  def ingredients(context \\ %{}) do
    Map.put(context, :ingredients, @ingredients)
  end

  def recipe(_context) do
    {:ok, recipe} = Recipes.create_recipe(@recipe)
    %{recipe: %{recipe: recipe, attrs: @recipe}}
  end

  def recipe_with_categories(_context) do
    {:ok, recipe} = Recipes.create_recipe(@recipe_with_categories)
    %{recipe_with_categories: %{recipe: recipe, attrs: @recipe_with_categories}}
  end

  def recipe_with_ingredients(_context) do
    {:ok, recipe} = Recipes.create_recipe(@recipe_with_ingredients)
    %{recipe_with_ingredients: %{recipe: recipe, attrs: @recipe_with_ingredients}}
  end
end
