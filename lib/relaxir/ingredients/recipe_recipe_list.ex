defmodule Relaxir.IngredientGroceryList do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ingredient_grocery_lists" do
    belongs_to :ingredient, Relaxir.Ingredients.Ingredient
    belongs_to :grocery_list, Relaxir.GroceryLists.GroceryList
  end

  def changeset(recipe_list, attrs) do
    recipe_list
    |> cast(attrs, [:ingredient_id, :grocery_list_id])
    |> cast_assoc(:ingredient)
    |> cast_assoc(:grocery_list)
  end
end
