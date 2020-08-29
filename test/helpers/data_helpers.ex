defmodule Relaxir.DataHelpers do
  alias Relaxir.{Recipes, Repo}

  @ingredients %{
    ingredient: %{name: "ingredient"},
    ingredient_note: %{name: "ingredient_note", note: "diced 1 cm"},
    ingredient_amount: %{name: "ingredient_amount", amount: 2},
    ingredient_amount_fraction: %{name: "ingredient_amount_fraction", amount: 0.5},
    ingredient_amount_unit: %{name: "ingredient_amount_unit", amount: 0.25, unit: "cup"},
    ingredient_amount_units: %{name: "ingredient_amount_units", amount: 2.5, unit: "teaspoons"},
    invalid_ingredient: %{name: nil},
    invalid_ingredient_unit_not_found: %{name: "invalid_ingredient_unit_not_found", amount: 1, unit: "invalid"},
    invalid_ingredient_unit_singular: %{name: "invalid_ingredient_unit_singular", amount: 50, unit: "cup"},
    invalid_ingredient_unit_plural: %{name: "invalid_ingredient_unit_plural", amount: 1, unit: "cups"}
  }

  @recipe %{
    title: "recipe",
    directions: "recipe directions",
    categories: [],
    ingredients: []
  }

  @recipe_with_categories %{
    title: "recipe_with_categories",
    directions: "recipe with categories directions",
    categories: ["category1", "category2"],
    ingredients: []
  }

  @recipe_with_ingredients %{
    directions: "recipe with ingredients directions",
    title: "recipe_with_ingredients",
    categories: [],
    ingredients: [
      @ingredients.ingredient,
      @ingredients.ingredient_note
    ]
  }

  def ingredients(context \\ %{}) do
    Map.put(context, :ingredients, @ingredients)
  end

  def recipe(context \\ %{}) do
    attrs = Map.get(context, :recipe, @recipe)

    %{recipe: Recipes.create_recipe!(attrs), attrs: attrs}
    |> append_to_recipes(context)
  end

  def recipe_with_categories(context \\ %{}) do
    attrs = Map.get(context, :recipe_categories, @recipe_with_categoreis)

    %{recipe: Recipes.create_recipe!(attrs), attrs: attrs}
    |> append_to_recipes(context)
  end

  def recipe_with_ingredients(context \\ %{}) do
    attrs = Map.get(context, :recipe_ingredients, @recipe_with_ingredients)

    %{recipe: Recipes.create_recipe!(attrs), attrs: attrs}
    |> append_to_recipes(context)
  end

  defp append_to_recipes(recipe, context \\ %{}) do
    recipes = Map.get(context, :recipes) || []
    Map.put(context, :recipes, [recipe | recipes])
  end
end
