defmodule Relaxir.Ingredients.Food do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :fdc_id,
    :data_type,
    :description,
    :food_category_id,
    :publication_date
  ]

  def get_fields(), do: @fields

  @derive {Jason.Encoder, only: @fields}

  schema "food" do
    field :fdc_id, :id
    field :data_type, :string
    field :description, :string
    field :food_category_id, :id
    field :publication_date, :string

    timestamps()
  end

  @doc false
  def changeset(ingredient, attrs) do
    ingredient
    |> cast(attrs, @fields)
    |> validate_required([:fdc_id, :data_type])
  end
end

