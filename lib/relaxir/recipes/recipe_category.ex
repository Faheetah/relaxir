defmodule Relaxir.RecipeCategory do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "recipe_categories" do
    belongs_to :recipe, Relaxir.Recipes.Recipe, primary_key: true
    belongs_to :category, Relaxir.Categories.Category, primary_key: true
  end

  def changeset(recipe_category, attrs) do
    recipe_category
    |> cast(attrs, [:recipe_id, :category_id])
    |> cast_assoc(:recipe)
    |> cast_assoc(:category)
  end
end
