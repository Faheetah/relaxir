defmodule Relaxir.GroceryLists.GroceryList do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grocery_lists" do
    field :name, :string
    field :note, :string
    belongs_to :user, Relaxir.Accounts.User
    has_many :ingredient_grocery_lists, Relaxir.IngredientGroceryList, on_replace: :delete, on_delete: :delete_all
    has_many :ingredients, through: [:ingredient_grocery_lists, :ingredient]

    timestamps()
  end

  def changeset(grocery_list, attrs) do
    grocery_list
    |> cast(attrs, [:name, :note, :user_id])
    |> cast_assoc(:ingredient_grocery_lists)
    |> validate_required([:name, :user_id])
    |> unique_constraint([:name])
  end
end
