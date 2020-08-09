defmodule Relaxir.IngredientImporter do
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Relaxir.Repo
  alias Relaxir.Ingredients.Food

  Logger.configure(level: :warn)

  def import!(path) do
    do_import(path)
    |> Stream.map(&(Food.changeset(%Food{}, &1)))
    |> Enum.each(&Relaxir.Repo.insert!/1)
  end

  def import(path) do
    do_import(path)
    |> Stream.map(&(Food.changeset(%Food{}, &1)))
    |> Stream.chunk_every(1000)
    |> Stream.with_index
    |> Enum.each(&insert_multiple/1)
  end

  def insert_multiple({entries, index}) do
    IO.write "Batch #{index + 1}"
    entries
    |> Enum.reduce(Multi.new(), fn(entry, multi) -> Multi.insert(multi, entry.changes.fdc_id, entry, on_conflict: :nothing) end)
    |> Repo.transaction
    IO.write ".. done\n"
  end

  def do_import(path) do
    [:postgrex, :ecto]
    |> Enum.each(&Application.ensure_all_started/1)
    Repo.start_link

    stream = path
    |> Path.expand
    |> Path.join("food.csv")
    |> File.stream!

    headers = stream
    |> Enum.take(1)
    |> CSV.decode!
    |> Enum.to_list
    |> List.first

    stream
    |> Stream.drop(1)
    |> CSV.decode!(headers: headers)
  end
end
