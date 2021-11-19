defmodule Relaxir.Usda.FoodNutrient do
  use Ecto.Schema
  import Ecto.Changeset

  schema "food_nutrients" do
    field :amount, :string
    field :data_points, :integer
    field :derivation_id, :integer
    field :footnote, :string
    field :max, :float
    field :median, :float
    field :min, :float
    field :min_year_acquired, :integer
    belongs_to :food, Relaxir.Usda.Food, foreign_key: :fdc_id
    belongs_to :nutrient, Relaxir.Usda.Nutrient

    timestamps()
  end

  @doc false
  def changeset(food_nutrient, attrs) do
    food_nutrient
    |> cast(attrs, [
      :id,
      :nutrient_id,
      :fdc_id,
      :amount,
      :data_points,
      :derivation_id,
      :min,
      :max,
      :median,
      :footnote,
      :min_year_acquired
    ])
    |> cast_assoc(:food)
    |> cast_assoc(:nutrient)
  end
end
