defmodule Relaxir.InventoryLists.InventoryList do
  use Ecto.Schema
  import Ecto.Changeset

  schema "inventory_lists" do
    field :name, :string
    belongs_to :user, Relaxir.Accounts.User
    has_many :ingredient_inventory_lists, Relaxir.IngredientInventoryList, on_replace: :delete, on_delete: :delete_all
    has_many :ingredients, through: [:ingredient_inventory_lists, :ingredient]

    timestamps()
  end

  def changeset(inventory_list, attrs) do
    inventory_list
    |> cast(attrs, [:name, :user_id])
    |> cast_assoc(:ingredient_inventory_lists)
    |> validate_required([:name, :user_id])
    |> unique_constraint([:name])
  end
end
