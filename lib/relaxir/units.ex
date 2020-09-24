defmodule Relaxir.Units do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.Units.Unit

  def get_unit_by_name(name) do
    singular = Inflex.singularize(name)
    plural = Inflex.pluralize(name)

    Unit
    |> where([u], u.name in [^singular, ^plural])
    |> Repo.one
  end

  def create_unit(attrs) do
    %Unit{}
    |> Unit.changeset(%{name: Inflex.singularize(attrs.name)})
    |> Repo.insert()
  end

  def delete_unit(%Unit{} = unit) do
    Repo.delete(unit)
  end

  def list_units() do
    Repo.all(Unit)
  end
end
