defmodule Relaxir.RecipeCategory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recipe_categories" do
    belongs_to :recipe, Relaxir.Recipes.Recipe
    belongs_to :category, Relaxir.Categories.Category
  end

  def changeset(recipe_category, attrs) do
    recipe_category
    |> cast(attrs, [:recipe_id, :category_id])
    |> cast_assoc(:recipe)
    |> cast_assoc(:category)
  end
end
