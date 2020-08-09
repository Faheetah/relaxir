defmodule Relaxir.Ingredients.FoodNutrient do
  use Ecto.Schema
  import Ecto.Changeset

  schema "food_nutrients" do
    field :amount, :string
    field :data_points, :integer
    field :derivation_id, :integer
    field :fdc_id, :integer
    field :footnote, :string
    field :max, :float
    field :median, :float
    field :min, :float
    field :min_year_acquired, :integer
    field :nutrient_id, :integer

    timestamps()
  end

  @doc false
  def changeset(food_nutrient, attrs) do
    food_nutrient
    |> cast(attrs, [:id, :fdc_id, :nutrient_id, :amount, :data_points, :derivation_id, :min, :max, :median, :footnote, :min_year_acquired])
  end
end
