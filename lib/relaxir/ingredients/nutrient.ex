defmodule Relaxir.Ingredients.Nutrient do
  use Ecto.Schema
  import Ecto.Changeset

  schema "nutrients" do
    field :name, :string
    field :nutrient_nbr, :string
    field :rank, :integer
    field :unit_name, :string

    timestamps()
  end

  @doc false
  def changeset(nutrient, attrs) do
    nutrient
    |> cast(attrs, [:id, :name, :unit_name, :nutrient_nbr, :rank])
  end
end
