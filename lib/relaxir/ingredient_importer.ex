defmodule Relaxir.IngredientImporter do
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Relaxir.Repo
  alias Relaxir.Ingredients

  @structs %{
    "Food" => Ingredients.Food,
    "FoodNutrient" => Ingredients.FoodNutrient,
    "Nutrient" => Ingredients.Nutrient
  }

  Logger.configure(log: :info)

  def import(module_name, path) do
    module = @structs[module_name]

    do_import(path)
    |> Stream.map(&module.changeset(struct(module, %{}), &1))
    |> Stream.chunk_every(1000)
    |> Stream.with_index()
    |> Enum.each(&insert_multiple(&1))
  end

  def insert_multiple({entries, index}) do
    IO.write("Batch #{index + 1}")

    entries
    |> Enum.reduce(Multi.new(), fn entry, multi ->
      Multi.insert(multi, entry, entry, on_conflict: :nothing)
    end)
    |> Repo.transaction()
    |> get_error

    IO.write(".. done\n")
  end

  def get_error(msg) do
    case msg do
      # {:error, 
      # #Ecto.Changeset<action: nil, changes: %{derivation_id: 71, fdc_id: 344604, id: 6320396, nutrient_id: 1003}, errors: [amount: {"is invalid", [type: :integer, validation: :cast]}], data: #Relaxir.Ingredients.FoodNutrient<>, valid?: false>, #Ecto.Changeset<action: :insert, changes: %{derivation_id: 71, fdc_id: 344604, id: 6320396, nutrient_id: 1003}, errors: [amount: {"is invalid", [type: :integer, validation: :cast]}], data: #Relaxir.Ingredients.FoodNutrient<>, valid?: false>, 
      #  %{}
      # }
      {:error, err, _, _} -> IO.inspect(err)
      _ -> true
    end
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
