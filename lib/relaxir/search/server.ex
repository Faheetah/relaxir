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

  def handle_call({:get, table, item}, _from, state) do
    {duration, results} =
      :timer.tc(fn ->
        items = split_terms(item)

        found =
          items
          |> Enum.map(fn item -> Cache.get(table, item) end)
          |> hd
          |> filter_items(items)

        {:reply, found, state}
      end)

    :telemetry.execute([:search, :query], %{total_time: duration})
    results
  end

  def handle_call({:set, table, {indexed_item, items}}, _from, state) do
    unless indexed_item == nil || indexed_item == "" do
      parse_item(indexed_item)
      |> Enum.each(fn i ->
        Cache.insert(table, List.to_tuple([Inflex.singularize(String.downcase(i)) | items]))
      end)
    end

    {:reply, :ok, state}
  end

  def handle_call({:delete, table, {indexed_item, items}}, _from, state) do
    unless indexed_item == nil || indexed_item == "" do
      parse_item(indexed_item)
      |> Enum.each(fn i ->
        Cache.delete(table, List.to_tuple([Inflex.singularize(String.downcase(i)) | items]))
      end)
    end

    {:reply, :ok, state}
  end

  ## Private logic

  defp split_terms(item) do
    Regex.scan(~r/[a-zA-Z]+/, item)
    |> Enum.map(fn [i] -> i end)
    |> Enum.reject(&(&1 == "" || &1 == nil))
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.downcase/1)
    |> Enum.map(&Inflex.singularize/1)
    |> Enum.reject(&(&1 == "" || &1 == nil))
    |> Enum.sort()
  end

  defp filter_items(results, items) do
    results
    |> Enum.dedup_by(&elem(&1, 1))
    |> Enum.reduce(%{}, fn found_item, acc ->
      name = parse_item_name(found_item)
      length = Enum.count(items -- items -- name) + 1 / String.length(elem(found_item, 1))
      Map.update(acc, found_item, length, &(&1 + length))
    end)
    |> Enum.sort_by(fn {_, score} -> score end, :desc)
  end

  defp parse_item_name(item) do
    Regex.scan(~r/[a-zA-Z]+/, elem(item, 1))
    |> Enum.map(fn [i] -> i end)
    |> Enum.reject(&(&1 == "" || &1 == nil))
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.downcase/1)
    |> Enum.map(&Inflex.singularize/1)
    |> Enum.reject(&(&1 == "" || &1 == nil))
    |> Enum.sort()
  end

  defp parse_item(value) do
    Regex.scan(~r/[a-zA-Z]+/, value)
    |> Enum.map(fn [i] -> i end)
    |> Enum.reject(&(&1 == "" || &1 == nil))
    |> Enum.sort()
    |> Enum.dedup()
  end
end
