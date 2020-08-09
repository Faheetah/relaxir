defmodule Relaxir.Ingredients.Food do
  use Ecto.Schema
  import Ecto.Changeset

  schema "foods" do
    field :data_type, :string
    field :description, :string
    field :fdc_id, :integer
    field :food_category_id, :integer
    field :publication_date, :date

    timestamps()
  end

  @doc false
  def changeset(food, attrs) do
    food
    |> cast(attrs, [:fdc_id, :data_type, :description, :food_category_id, :publication_date])
  end
end
