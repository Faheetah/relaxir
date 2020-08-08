defmodule Relaxir.RecipeIngredient do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "recipes_ingredients" do
    belongs_to :recipe, Relaxir.Recipes.Recipe
    belongs_to :ingredient, Relaxir.Ingredients.Ingredient
  end

  def changeset(recipe_ingredient, attrs) do
    recipe_ingredient
    |> cast(attrs, [:recipes, :ingredients])
    |> validate_required([])
  end
end
