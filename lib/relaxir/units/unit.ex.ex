defmodule Relaxir.Units.Unit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "units" do
    field :name, :string
  end

  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint([:name])
  end
end
