defmodule Relaxir.Units do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.Units.Unit

  def get_unit_by_name(name) do
    singular = Inflex.singularize(name)
    plural = Inflex.pluralize(name)

    Unit
    |> where([u], u.name in [^singular, ^plural] or u.abbreviation in [^singular, ^plural])
    |> Repo.one
  end

  def create_unit(attrs) do
    abbreviation = attrs
    |> Map.get(:abbreviation)
    |> Inflex.singularize()

    %Unit{}
    |> Unit.changeset(%{name: Inflex.singularize(attrs.name), abbreviation: abbreviation})
    |> Repo.insert()
  end

  def update_unit(%Unit{} = unit, attrs) do
    unit
    |> Unit.changeset(attrs)
    |> Repo.update()
  end

  def delete_unit(%Unit{} = unit) do
    Repo.delete(unit)
  end

  def delete_unit_by_id(id) do
    unit = Repo.get(Unit, id)
    Repo.delete(unit)
  end

  def list_units() do
    Repo.all(Unit)
  end
end
