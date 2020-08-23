defmodule Relaxir.RecipeIngredient do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recipe_ingredients" do
    field :amount, :integer
    field :note, :string
    belongs_to :unit, Relaxir.Ingredients.Unit
    belongs_to :recipe, Relaxir.Recipes.Recipe
    belongs_to :ingredient, Relaxir.Ingredients.Ingredient
  end

  def changeset(recipe_ingredient, attrs) do
    recipe_ingredient
    |> cast(attrs, [:recipe_id, :ingredient_id, :unit_id, :amount, :note])
    |> cast_assoc(:recipe)
    |> cast_assoc(:ingredient)
  end
end
