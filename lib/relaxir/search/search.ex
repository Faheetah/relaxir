defmodule Relaxir.Search do
  use GenServer

  ## Public API

  # Relaxir.Search.delete(Relaxir.Ingredients.Food, :description, {"Green Tomatoes", ["Green Tomatoes", 1]})
  def delete(module, name, item) do
    table = atom_from_module(module, name)
    GenServer.call(__MODULE__, {:delete, table, item}, 500)
  end

  # Relaxir.Search.set(Relaxir.Ingredients.Food, :description, {"Green Tomatoes", ["Green Tomatoes", 1]})
  def set(module, name, item) do
    table = atom_from_module(module, name)
    GenServer.call(__MODULE__, {:set, table, item}, 500)
  end

  # Relaxir.Search.get(Relaxir.Ingredients.Food, :description, "green tomatoes")
  def get(module, name, item) do
    table = atom_from_module(module, name)

    case GenServer.call(__MODULE__, {:get, table, item}, 500) do
      [] -> {:error, :not_found}
      results -> {:ok, results}
    end
  end

  ## Telemetry

  def get_count(module, field, _) do
    table = new_atom_from_module(module, field)
    total = case :ets.info(table) do
      :undefined -> 0
      t -> t[:size]
    end

    :telemetry.execute([:search, :items, table], %{total: total})
  end

  ## Parsing table names

  # :table_name -> Elixir.Table.Name
  def module_from_atom(table) do
    table
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> List.insert_at(0, "Elixir")
    |> Enum.join(".")
    |> String.to_existing_atom()
  end

  # Elixir.Table.Name -> :table_name
  def atom_from_module(module, name) do
    parse_atom_from_module(module, name)
    |> String.to_existing_atom()
  end

  defp new_atom_from_module(module, name) do
    parse_atom_from_module(module, name)
    |> String.to_atom()
  end

  defp parse_atom_from_module(module, name) do
    module
    |> Atom.to_string()
    |> String.split(".")
    |> Enum.map(&String.downcase/1)
    |> List.delete_at(0)
    |> Enum.concat([Atom.to_string(name)])
    |> Enum.join("_")
  end

  ## Genserver

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      [
        {:tables, opts[:tables]},
        {:repo, opts[:repo]},
        {:log_limit, 1_000_000}
      ],
      opts
    )
  end

  def init(args) do
    Process.send_after(self(), :hydrate, 0)

    {:ok, args}
  end

  def handle_info(:hydrate, args) do
    [{:tables, tables}, {:repo, repo}, {:log_limit, _}] = args

    Enum.each(tables, fn {table, indexed_field, fields} ->
      table_name = new_atom_from_module(table, indexed_field)
      :ets.new(table_name, [:named_table, :duplicate_bag, :private])

      table_name = atom_from_module(table, indexed_field)

      table
      |> repo.all
      |> Enum.map(fn record ->
        {Map.get(record, indexed_field), Enum.map(fields, fn f -> Map.get(record, f) end)}
      end)
      |> Enum.sort_by(fn {indexed_field, _} -> indexed_field end)
      |> Enum.dedup_by(fn {indexed_field, _} -> indexed_field end)
      |> Enum.each(&insert_item(table_name, &1))
    end)

    {:noreply, args}
  end

  # this search takes an absurdly long time the longer the search terms are
  # it does not scale well at all, but could be useful for correlating possible similar ingredients
  # future suggestion, only take a single word at a time, and don't parse through word by word
  def handle_call({:get_fuzzy, table, item}, _from, state) do
    items =
      Regex.scan(~r/[a-zA-Z]+/, item)
      |> Enum.map(fn [i] -> i end)
      |> Enum.reject(&(&1 == "" || &1 == nil))
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.downcase/1)
      |> Enum.reject(&(&1 == "" || &1 == nil))

    prefixes = Enum.map(items, &String.first/1)

    # :ets.fun2ms(fn {"letter", word, full} -> {word, full} end)
    # Where "letter" is being passed in as k
    results =
      :ets.select(table, for(k <- prefixes, do: {{k, :"$1", :"$2"}, [], [{{:"$1", :"$2"}}]}))
      |> Stream.map(fn {k, v} -> {compare_multiple(k, items), v} end)
      |> Stream.reject(fn {{i, _}, _} -> i < 0.85 end)
      |> Enum.reduce(%{}, fn i, acc ->
        {{score, _}, name} = i
        Map.update(acc, name, 1, &(&1 + score + 100 / String.length(name)))
      end)
      |> Enum.sort_by(fn {_, score} -> score end, :desc)
      |> Enum.take(20)

    {:reply, results, state}
  end

  def handle_call({:get, table, item}, _from, state) do
    {duration, return} =
      :timer.tc(fn ->
        items =
          Regex.scan(~r/[a-zA-Z]+/, item)
          |> Enum.map(fn [i] -> i end)
          |> Enum.reject(&(&1 == "" || &1 == nil))
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.downcase/1)
          |> Enum.map(&Inflex.singularize/1)
          |> Enum.reject(&(&1 == "" || &1 == nil))

        results =
          Enum.map(items, fn item ->
            :ets.lookup(table, item)
          end)
          |> hd
          |> Enum.dedup_by(&elem(&1, 1))
          |> Enum.reduce(%{}, fn item, acc ->
            name = elem(item, 1)
            length = 1 + 1 / String.length(name)
            Map.update(acc, item, length, &(&1 + length))
          end)
          |> Enum.sort_by(fn {_, score} -> score end, :desc)

        {:reply, results, state}
      end)

    :telemetry.execute([:search, :query], %{total_time: duration})
    return
  end

  def handle_call({:set, table_name, {indexed_item, items}}, _from, state) do
    insert_item(table_name, {indexed_item, items})
    {:reply, :ok, state}
  end

  def handle_call({:delete, table_name, {indexed_item, items}}, _from, state) do
    delete_item(table_name, {indexed_item, items})
    {:reply, :ok, state}
  end

  ## Private logic

  defp compare(left, right) do
    cond do
      left == right -> 1.0
      true -> String.jaro_distance(left, right)
    end
  end

  defp compare_multiple(left, rights) do
    rights
    |> Enum.map(&{compare(&1, left), left})
    |> Enum.sort_by(fn {i, _} -> i end, :desc)
    |> hd
  end

  defp parse_item(value) do
    Regex.scan(~r/[a-zA-Z]+/, value)
    |> Enum.map(fn [i] -> i end)
    |> Enum.reject(&(&1 == "" || &1 == nil))
    |> Enum.sort()
    |> Enum.dedup()
  end

  defp insert_item(table_name, {indexed_item, items}) do
    unless indexed_item == nil || indexed_item == "" do
      parse_item(indexed_item)
      |> Enum.each(fn i ->
        :ets.insert(table_name, List.to_tuple([Inflex.singularize(String.downcase(i)) | items]))
      end)
    end
  end

  defp delete_item(table_name, {indexed_item, items}) do
    unless indexed_item == nil || indexed_item == "" do
      parse_item(indexed_item)
      |> Enum.each(fn i ->
        :ets.delete_object(table_name, List.to_tuple([Inflex.singularize(String.downcase(i)) | items]))
      end)
    end
  end
end
