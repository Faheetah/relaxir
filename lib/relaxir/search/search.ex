defmodule Relaxir.Search do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [
      {:ets_table_name, :relaxir_search_table},
      {:log_limit, 1_000_000}
    ], opts)
  end

  def get(item) do
    case GenServer.call(__MODULE__, {:get, item}, 20000) do
      [] -> {:error, :not_found}
      results -> {:ok, results}
    end
  end

  def set(item) do
    GenServer.call(__MODULE__, {:set, item})
  end

  def compare(left, right) do
    cond do
      left == right -> {1.0, left}
      String.contains?(left, right) -> {0.9, left}
      true -> {String.bag_distance(left, right), left}
    end
  end

  def handle_call({:get, item}, _from, state) do
    %{ets_table_name: ets_table_name} = state

    results = :ets.match(ets_table_name, {:"$1"})
    |> Stream.flat_map(fn i -> i end)
    |> Stream.reject(&(&1 == nil))
    |> Stream.map(&String.downcase/1)
    |> Stream.map(&(compare(&1, item)))
    |> Stream.reject(fn {i, _} -> i < 0.7 end)
    |> Stream.take(100)
    |> Enum.reverse
    |> List.keysort(0)
    |> Enum.take(5)

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
