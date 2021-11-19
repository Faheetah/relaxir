defmodule Relaxir.Usda.Food do
  use Ecto.Schema
  import Ecto.Changeset
  alias Relaxir.Usda.FoodNutrient

  schema "foods" do
    field :data_type, :string
    field :description, :string
    field :fdc_id, :integer
    field :food_category_id, :integer
    field :publication_date, :date
    has_many :food_nutrients, FoodNutrient, foreign_key: :fdc_id, references: :fdc_id
    has_many :nutrients, through: [:food_nutrients, :nutrient]

    timestamps()
  end

  @doc false
  def changeset(food, attrs) do
    food
    |> cast(attrs, [:fdc_id, :data_type, :description, :food_category_id, :publication_date])
    |> cast_assoc(:food_nutrients)
    |> unique_constraint([:description])
  end
end
