defmodule Relaxir.Ingredients.Unit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "units" do
    field :singular, :string
    field :plural, :string
  end

  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [:singular, :plural])
    |> validate_required([:singular, :plural])
    |> unique_constraint([:singular, :plural])
  end
end
