defmodule Relaxir.Search do
  require Logger

  alias Relaxir.Search.Cache
  alias Relaxir.Search.Server
  alias Relaxir.Search.Helpers

  ## Public API

  # Relaxir.Search.delete(Relaxir.Ingredients.Food, :description, {"Green Tomatoes", ["Green Tomatoes", 1]})
  def delete(module, name, item) do
    table = Helpers.atom_from_module(module, name)
    GenServer.call(Server, {:delete, table, item}, 500)
  end

  # Relaxir.Search.set(Relaxir.Ingredients.Food, :description, {"Green Tomatoes", ["Green Tomatoes", 1]})
  def set(module, name, item) do
    table = Helpers.atom_from_module(module, name)
    GenServer.call(Server, {:set, table, item}, 500)
  end

  # Relaxir.Search.get(Relaxir.Ingredients.Food, :description, "green tomatoes")
  def get(module, name, item) do
    call =
      try do
        table = Helpers.atom_from_module(module, name)
        GenServer.call(Server, {:get, table, item}, 5000)
      rescue
        ArgumentError ->
          atom = Helpers.parse_atom_from_module(module, name)

          Logger.error("
            Table #{atom} does not exist in ETS.
            Is #{module}/#{name} configured in the cache?
            Verify the Relaxir.Search.Hydrator application is configured with cache_tables.
          ")

          []
      end

    case call do
      [] -> {:error, :not_found}
      results -> {:ok, results}
    end
  end

  def get_count(module, field, _) do
    table = Helpers.new_atom_from_module(module, field)
    total = Cache.size(table)
    :telemetry.execute([:search, :items, table], %{total: total})
  end
end
