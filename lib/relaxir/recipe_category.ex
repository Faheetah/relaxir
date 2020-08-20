defmodule Relaxir.RecipeCategory do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "recipes_categories" do
    belongs_to :recipe, Relaxir.Recipes.Recipe
    belongs_to :category, Relaxir.Categories.Category
  end

  def changeset(recipe_category, attrs) do
    recipe_category
    |> cast(attrs, [:recipes, :categories])
  end
end
