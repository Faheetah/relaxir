defmodule Mix.Tasks.Relaxir.ModifyUnitsAddName do
  use Mix.Task

  alias Relaxir.Repo
  alias Relaxir.Ingredients.Unit

  @shortdoc "add name to units"
  def run(_) do
    [:postgrex, :ecto]
    |> Enum.each(&Application.ensure_all_started/1)

    Repo.start_link()

    Repo.all(Unit)
    |> Enum.each(fn unit ->
      unit
      |> Unit.changeset(%{name: unit.singular})
      |> Repo.update()
    end)
  end
end
