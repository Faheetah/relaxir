defmodule Relaxir.Inventory.Item do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.Accounts.User
  alias Relaxir.Ingredients.Ingredient
  alias Relaxir.Units.Unit
  alias Relaxir.Inventory.Inventory

  schema "items" do
    field :name, :string
    field :amount, :integer, default: 0
    field :note, :string

    belongs_to :user, User
    belongs_to :ingredient, Ingredient
    belongs_to :unit, Unit
    belongs_to :inventory, Inventory, foreign_key: :inventory_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:user_id, :ingredient_id, :unit_id, :inventory_id, :name, :amount, :note])
    |> validate_required([:user_id, :ingredient_id, :amount])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:ingredient_id)
    |> foreign_key_constraint(:unit_id)
    |> foreign_key_constraint(:inventory_id)
    |> unique_constraint([:user_id, :ingredient_id], name: :items_user_ingredient_unique)
  end

  @doc """
  Creates a changeset for updating the amount by a delta value.
  """
  def amount_changeset(item, delta) do
    new_amount = max(0, item.amount + delta)

    item
    |> cast(%{amount: new_amount}, [:amount])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
  end
end
