defmodule Relaxir.Usda.Nutrient do
  use Ecto.Schema
  import Ecto.Changeset
  alias Relaxir.Usda.FoodNutrient

  schema "nutrients" do
    field :name, :string
    field :nutrient_nbr, :string
    field :rank, :integer
    field :unit_name, :string
    has_many :food_nutrients, FoodNutrient
    has_many :foods, through: [:food_nutrients, :food]

    timestamps()
  end

  @doc false
  def changeset(nutrient, attrs) do
    nutrient
    |> cast(attrs, [:id, :name, :unit_name, :nutrient_nbr, :rank])
    |> cast_assoc(:food_nutrients)
    |> validate_required([:name, :unit_name, :nutrient_nbr, :rank])
  end
end
