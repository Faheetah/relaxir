defmodule Relaxir.Search do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [
      {:tables, opts[:tables]},
      {:repo, opts[:repo]},
      {:log_limit, 1_000_000}
    ], opts)
  end

  def get(module, name, item) do
    table = atom_from_module(module, name)
    case GenServer.call(__MODULE__, {:get, table, item}, 20000) do
      [] -> {:error, :not_found}
      results -> {:ok, results}
    end
  end

  def set(module, name, item) do
    table = atom_from_module(module, name)
    GenServer.call(__MODULE__, {:set, table, item})
  end

  defp compare(left, right) do
    cond do
      left == right -> {1.0, left}
      String.contains?(left, right) -> {0.9 + (0.1 / abs(String.length(left) - String.length(right))), left}
      true -> {String.jaro_distance(left, right), left}
    end
  end

  def handle_call({:get, table, item}, _from, state) do
    results =
      :ets.match(table, {:"$1"})
      |> Stream.flat_map(fn i -> i end)
      |> Stream.reject(&(&1 == nil))
      |> Stream.map(&String.downcase/1)
      |> Stream.map(&compare(&1, item))
      |> Stream.reject(fn {i, _} -> i < 0.7 end)
      |> Stream.take(100)
      |> Enum.sort_by(fn {i, _} -> i end, :desc)
      |> Enum.take(5)

    {:reply, results, state}
  end

  def handle_call({:set, table, item}, _from, state) do
    true = :ets.insert(table, {item})
    {:reply, :ok, state}
  end

  def init(args) do
    [{:tables, tables}, {:repo, repo}, {:log_limit, _}] = args

    Enum.each(tables, fn {table, fields} ->
      Enum.each(fields, fn field ->
        table_name = String.to_atom("#{table}_#{field}")
        :ets.new(table_name, [:named_table, :set, :private])

        module = module_from_atom(table)

        repo.all(module)
        |> Enum.each(fn i -> :ets.insert(table_name, {Map.get(i, field)}) end)
      end)
    end)

    {:ok, args}

  end

  defp module_from_atom(table) do
    table
    |> Atom.to_string
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> List.insert_at(0, "Elixir")
    |> Enum.join(".")
    |> String.to_existing_atom
  end

  defp atom_from_module(module, name) do
    module
    |> Atom.to_string
    |> String.split(".")
    |> Enum.map(&String.downcase/1)
    |> List.delete_at(0)
    |> Enum.concat([Atom.to_string(name)])
    |> Enum.join("_")
    |> String.to_existing_atom
  end
end
