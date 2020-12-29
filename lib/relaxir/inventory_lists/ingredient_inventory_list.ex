defmodule Relaxir.IngredientInventoryList do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ingredient_inventory_lists" do
    field :note, :string
    belongs_to :ingredient, Relaxir.Ingredients.Ingredient
    belongs_to :inventory_list, Relaxir.InventoryLists.InventoryList
  end

  def changeset(recipe_list, attrs) do
    recipe_list
    |> cast(attrs, [:ingredient_id, :inventory_list_id])
    |> cast_assoc(:ingredient)
    |> cast_assoc(:inventory_list)
  end
end
