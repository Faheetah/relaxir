defmodule Mix.Tasks.Relaxir.Import do
  use Mix.Task

  @shortdoc "Import USDA data into ingredients"
  def run(params) do
    [path | rest] = params

    case rest do
      ["--skip"|_] -> Relaxir.IngredientImporter.import(path)
      _ -> Relaxir.IngredientImporter.import!(path)
    end
  end
end
