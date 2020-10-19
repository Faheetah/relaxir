defmodule Relaxir.Units.Unit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "units" do
    field :name, :string
    field :abbreviation, :string
  end

  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [:name, :abbreviation])
    |> validate_required([:name])
    |> unique_constraint([:name])
    |> unique_constraint([:abbreviation])
  end
end
