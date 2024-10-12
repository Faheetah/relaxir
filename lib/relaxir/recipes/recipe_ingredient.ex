defmodule Relaxir.RecipeIngredient do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recipe_ingredients" do
    field :amount, :float
    field :note, :string
    field :order, :integer
    belongs_to :unit, Relaxir.Units.Unit
    belongs_to :recipe, Relaxir.Recipes.Recipe
    belongs_to :ingredient, Relaxir.Ingredients.Ingredient
    field :suggestion, :string, virtual: true
  end

  def changeset(recipe_ingredient, attrs) do
    recipe_ingredient
    |> cast(attrs, [:recipe_id, :ingredient_id, :unit_id, :amount, :note, :order])
    |> cast_assoc(:recipe)
    |> cast_assoc(:ingredient)
  end
end
