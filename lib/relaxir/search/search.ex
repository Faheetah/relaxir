defmodule Relaxir.Search do
  use GenServer

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

  def tomatoes() do
    food("green tomatoes")
  end

  def food(name) do
    # {"Tutturosso Green 14.5oz. Italian Diced Tomatoes", 3.0},
    :timer.tc(fn ->
      Relaxir.Search.get(Relaxir.Ingredients.Food, :description, name)
    end)
  end

  # Relaxir.Search.get(Relaxir.Ingredients.Food, :description, "green tomatoes")
  def get(module, name, item) do
    table = atom_from_module(module, name)

    case GenServer.call(__MODULE__, {:get, table, item}, 500) do
      [] -> {:error, :not_found}
      results -> {:ok, results}
    end
  end

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

  # this search takes an absurdly long time the longer the search terms are
  # it does not scale well at all, but could be useful for correlating possible similar ingredients
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
    {duration, return} = :timer.tc fn ->
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
        |> Enum.dedup_by(&(elem(&1, 1)))
        |> Enum.reduce(%{}, fn item, acc ->
          name = elem(item, 1)
          length = 1 + 1 / String.length(name)
          Map.update(acc, item, length, &(&1 + length))
        end)
        |> Enum.sort_by(fn {_, score} -> score end, :desc)

      {:reply, results, state}
    end

    :telemetry.execute([:relaxir, :search, :query], %{total_time: duration})
    return
  end

  def handle_call({:set, table_name, value}, _from, state) do
    parse_item(value)
    |> Enum.each(fn v ->
      :ets.insert(table_name, {Inflex.singularize(String.downcase(v)), value})
    end)
    {:reply, :ok, state}
  end

  def handle_call({:delete, table_name, value}, _from, state) do
    parse_item(value)
    |> Enum.each(fn v ->
      :ets.delete_object(table_name, {Inflex.singularize(String.downcase(v)), value})
    end)
    {:reply, :ok, state}
  end

  def delete(module, name, item) do
    table = atom_from_module(module, name)
    GenServer.call(__MODULE__, {:delete, table, item}, 500)
  end

  def set(module, name, item) do
    table = atom_from_module(module, name)
    GenServer.call(__MODULE__, {:set, table, item}, 500)
  end

  def parse_item(value) do
    Regex.scan(~r/[a-zA-Z]+/, value)
    |> Enum.map(fn [i] -> i end)
    |> Enum.reject(&(&1 == "" || &1 == nil))
    |> Enum.sort()
    |> Enum.dedup()
  end

  def init(args) do
    [{:tables, tables}, {:repo, repo}, {:log_limit, _}] = args

    Enum.each(tables, fn {table, fields} ->
      field = hd(fields)
      table_name = String.to_atom("#{table}_#{field}")
      :ets.new(table_name, [:named_table, :duplicate_bag, :private])
    end)

    Enum.each(tables, fn {table, fields} ->
      field = hd(fields)
      table_name = String.to_atom("#{table}_#{field}")
      module_from_atom(table)
      |> repo.all
      |> Enum.map(fn record ->
        Enum.map(fields, fn f -> Map.get(record, f) end)
      end)
      |> Enum.sort_by(&(hd(&1)))
      |> Stream.dedup_by(&(hd(&1)))
      |> Enum.each(fn fields ->
        key = hd(fields)
        unless key == nil || key == "" do
          parse_item(key)
          |> Enum.each(fn k ->
            :ets.insert(table_name, List.to_tuple([Inflex.singularize(String.downcase(k)) | fields]))
          end)
        end
      end)
    end)

    {:ok, args}
  end

  # table_name -> Elixir.Table.Name
  defp module_from_atom(table) do
    table
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> List.insert_at(0, "Elixir")
    |> Enum.join(".")
    |> String.to_existing_atom()
  end

  # Elixir.Table.Name -> table_name
  defp atom_from_module(module, name) do
    module
    |> Atom.to_string()
    |> String.split(".")
    |> Enum.map(&String.downcase/1)
    |> List.delete_at(0)
    |> Enum.concat([Atom.to_string(name)])
    |> Enum.join("_")
    |> String.to_existing_atom()
  end
end
