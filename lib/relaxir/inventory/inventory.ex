defmodule Relaxir.Inventory.Inventory do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.Accounts.User
  alias Relaxir.Inventory.Item

  @icon_options [
    "refrigerator_french",
    "refrigerator_top",
    "freezer_chest",
    "shelf",
    "table"
  ]

  schema "inventories" do
    field :name, :string
    field :icon, :string, default: "shelf"

    belongs_to :user, User
    has_many :items, Item, on_delete: :nilify_all

    timestamps(type: :utc_datetime)
  end

  def icon_options, do: @icon_options

  @doc false
  def changeset(inventory, attrs) do
    inventory
    |> cast(attrs, [:user_id, :name, :icon])
    |> validate_required([:user_id, :name])
    |> validate_inclusion(:icon, @icon_options)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :name], name: :inventories_user_name_unique)
  end
end
