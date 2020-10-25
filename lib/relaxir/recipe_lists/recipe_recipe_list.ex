defmodule Relaxir.RecipeRecipeList do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recipe_recipe_lists" do
    belongs_to :recipe, Relaxir.Recipes.Recipe
    belongs_to :recipe_list, Relaxir.RecipeLists.RecipeList
  end

  def changeset(recipe_list, attrs) do
    recipe_list
    |> cast(attrs, [:recipe_id, :recipe_list_id])
    |> cast_assoc(:recipe)
    |> cast_assoc(:recipe_list)
  end
end
