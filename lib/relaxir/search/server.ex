defmodule Relaxir.Search.Server do
  use GenServer

  require Logger

  alias Relaxir.Search.Cache

  def start_link(tables: tables) do
    GenServer.start_link(
      __MODULE__,
      [
        {:tables, tables},
        {:log_limit, 1_000_000}
      ],
      name: __MODULE__
    )
  end

  def init(args) do
    Logger.info("Search core started")
    {:ok, args}
  end

  ## GenServer functions

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
      Cache.get_fuzzy(table, for(k <- prefixes, do: {{k, :"$1", :"$2"}, [], [{{:"$1", :"$2"}}]}))
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
    {duration, results} =
      :timer.tc(fn ->
        items =
          Regex.scan(~r/[a-zA-Z]+/, item)
          |> Enum.map(fn [i] -> i end)
          |> Enum.reject(&(&1 == "" || &1 == nil))
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.downcase/1)
          |> Enum.map(&Inflex.singularize/1)
          |> Enum.reject(&(&1 == "" || &1 == nil))

        found =
          Enum.map(items, fn item ->
            Cache.get(table, item)
          end)
          |> hd
          |> Enum.dedup_by(&elem(&1, 1))
          |> Enum.reduce(%{}, fn item, acc ->
            name = elem(item, 1)
            length = 1 + 1 / String.length(name)
            Map.update(acc, item, length, &(&1 + length))
          end)
          |> Enum.sort_by(fn {_, score} -> score end, :desc)

        {:reply, found, state}
      end)

    :telemetry.execute([:search, :query], %{total_time: duration})
    results
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

  def insert_item(table, {indexed_item, items}) do
    unless indexed_item == nil || indexed_item == "" do
      parse_item(indexed_item)
      |> Enum.each(fn i ->
        Cache.insert(table, List.to_tuple([Inflex.singularize(String.downcase(i)) | items]))
      end)
    end
  end

  def delete_item(table_name, {indexed_item, items}) do
    unless indexed_item == nil || indexed_item == "" do
      parse_item(indexed_item)
      |> Enum.each(fn i ->
        Cache.delete(table_name, List.to_tuple([Inflex.singularize(String.downcase(i)) | items]))
      end)
    end
  end
end
