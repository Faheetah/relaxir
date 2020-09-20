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

    case GenServer.call(__MODULE__, {:get, table, item}, 5000) do
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
    items =
      Regex.scan(~r/[a-zA-Z]+/, item)
      |> Enum.map(fn [i] -> i end)
      |> Enum.reject(&(&1 == "" || &1 == nil))
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.downcase/1)
      |> Enum.map(&Inflex.singularize/1)
      |> Enum.reject(&(&1 == "" || &1 == nil))

    # :ets.fun2ms(fn {keyword, full} -> {full} end)
    results =
      :ets.select(table, for(i <- items, do: {{i, :"$1"}, [], [:"$_"]}))
      |> Enum.dedup()
      |> Enum.reduce(%{}, fn {_, name}, acc ->
        length = 1 + 1 / String.length(name)
        Map.update(acc, name, length, &(&1 + length))
      end)
      |> Enum.sort_by(fn {_, score} -> score end, :desc)

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
        :ets.new(table_name, [:named_table, :duplicate_bag, :private])

        module_from_atom(table)
        |> repo.all
        |> Enum.map(fn i ->
          Map.get(i, field)
        end)
        |> Enum.sort()
        |> Stream.dedup()
        |> Enum.each(fn value ->
          unless value == nil || value == "" do
            Regex.scan(~r/[a-zA-Z]+/, value)
            |> Enum.map(fn [i] -> i end)
            |> Enum.reject(&(&1 == "" || &1 == nil))
            |> Enum.sort()
            |> Enum.dedup()
            |> Enum.each(fn v ->
              :ets.insert(table_name, {Inflex.singularize(String.downcase(v)), value})
            end)
          end
        end)
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
