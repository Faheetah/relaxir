defmodule Relaxir.Search do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [
      {:ets_table_name, :relaxir_search_table},
      {:log_limit, 1_000_000}
    ], opts)
  end

  def get(item) do
    case GenServer.call(__MODULE__, {:get, item}) do
      [] -> {:error, :not_found}
      results -> {:ok, results}
    end
  end

  def set(item) do
    GenServer.call(__MODULE__, {:set, item})
  end

  def handle_call({:get, item}, _from, state) do
    %{ets_table_name: ets_table_name} = state

    results = :ets.match(ets_table_name, {:"$1"})
    |> List.flatten
    |> Enum.map(fn i -> {String.bag_distance(i, item), i} end)
    |> List.keysort(0)
    |> Enum.reject(fn {i, _} -> i < 0.5 end)

    {:reply, results, state}
  end

  def handle_call({:set, item}, _from, state) do
    %{ets_table_name: ets_table_name} = state
    true = :ets.insert(ets_table_name, {item})
    {:reply, state}
  end

  def init(args) do
    [{:ets_table_name, ets_table_name}, {:log_limit, log_limit}] = args
    :ets.new(ets_table_name, [:named_table, :set, :private])

    Relaxir.Ingredients.list_ingredients()
    |> Enum.each(fn i -> :ets.insert(ets_table_name, {i.name}) end)

    {:ok, %{log_limit: log_limit, ets_table_name: ets_table_name}}
  end
end
