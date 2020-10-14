defmodule Relaxir.Search.Cache do
  use GenServer

  def start_link(tables) do
    table_names = tables
    |> Enum.map(fn {t, f, _} -> Relaxir.Search.new_atom_from_module(t, f) end)
    GenServer.start_link(__MODULE__, table_names, name: __MODULE__)
  end

  def insert(table, item) do
    GenServer.cast(__MODULE__, {:insert, table, item})
  end

  def delete(table, item) do
    GenServer.cast(__MODULE__, {:delete, table, item})
  end

  def size(table) do
    GenServer.call(__MODULE__, {:size, table})
  end

  def get(table, item) do
    GenServer.call(__MODULE__, {:get, table, item}, 500)
  end

  def get_fuzzy(table, items) do
    GenServer.cast(__MODULE__, {:get_fuzzy, table, items})
  end

  def init(tables) do
    Enum.each(tables, fn table ->
      :ets.new(table, [:named_table, :duplicate_bag, :private])
    end)
    {:ok, tables}
  end

  def handle_cast({:insert, table, item}, state) do
    :ets.insert(table, item)
    {:noreply, state}
  end

  def handle_cast({:delete, table, item}, state) do
    :ets.delete_object(table, item)
    {:noreply, state}
  end

  def handle_call({:size, table}, _from, state) do
    total = case :ets.info(table) do
      :undefined -> 0
      t -> t[:size]
    end
    {:reply, total, state}
  end

  def handle_call({:get, table, item}, _from, state) do
    results = :ets.lookup(table, item)
    {:reply, results, state}
  end

  def handle_call({:get_fuzzy, table, items}, _from, state) do
    results = :ets.select(table, for(k <- items, do: {{k, :"$1", :"$2"}, [], [{{:"$1", :"$2"}}]}))
    {:reply, results, state}
  end
end
