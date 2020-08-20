defmodule Relaxir.RecipeIngredient do
  use Ecto.Schema
  import Ecto.Changeset
  alias Relaxir.Recipes.Recipe
  alias Relaxir.Ingredients.Ingredient

  schema "recipe_ingredients" do
    belongs_to :recipe, Recipe, foreign_key: :recipe_id
    belongs_to :ingredient, Ingredient, foreign_key: :ingredient_id
  end

  def changeset(recipe_ingredient, attrs) do
    recipe_ingredient
    |> cast(attrs, [:recipe_id, :ingredient_id])
    |> cast_assoc(:recipe)
    |> cast_assoc(:ingredient)
  end
end
