defmodule Relaxir.IngredientImporter do
  import Ecto.Query, warn: false
  alias Relaxir.Repo
  alias Relaxir.Ingredients
  alias Relaxir.Usda

  @structs %{
    "Food" => Usda.Food,
    "FoodNutrient" => Usda.FoodNutrient,
    "Nutrient" => Ingredients.Nutrient
  }

  Logger.configure(level: :info)

  def import(module_name, path) do
    module = @structs[module_name]
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    do_import(path)
    |> Stream.map(&module.changeset(struct(module, %{}), &1))
    |> Stream.filter(fn entry -> entry.valid? == true end)
    |> Stream.map(&Ecto.Changeset.apply_changes/1)
    |> Stream.map(&Map.take(&1, module.__schema__(:fields)))
    |> Stream.map(fn entry ->
      entry
      # |> Map.drop([:id])
      |> Map.merge(%{inserted_at: now, updated_at: now})
    end)
    |> Stream.chunk_every(1000)
    |> Stream.with_index()
    |> Stream.map(fn {chunk, index} ->
      IO.puts("Inserted records: #{index + 1}k")
      chunk
    end)
    |> Enum.each(fn chunk -> Repo.insert_all(module, chunk, on_conflict: :nothing) end)
  end

  def do_import(path) do
    [:postgrex, :ecto]
    |> Enum.each(&Application.ensure_all_started/1)

    Repo.start_link()

    stream =
      path
      |> Path.expand()
      |> File.stream!()

    headers =
      stream
      |> Enum.take(1)
      |> CSV.decode!()
      |> Enum.to_list()
      |> List.first()

    stream
    |> Stream.drop(1)
    |> CSV.decode!(headers: headers)
  end
end
