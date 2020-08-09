defmodule Mix.Tasks.Relaxir.Import do
  use Mix.Task 

  Logger.configure(log: :info)

  @shortdoc "Import USDA data into ingredients"
  def run(params) do
    parsed_params = Relaxir.Mix.Helpers.parse_args params
    [module, path] = parsed_params[:positionals]
    Relaxir.IngredientImporter.import(module, path)
  end
end
