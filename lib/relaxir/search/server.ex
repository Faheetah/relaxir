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
          |> Enum.reduce(%{}, fn found_item, acc ->
            name = String.downcase(elem(found_item, 1))
            length = (1 / (Enum.count(items -- items -- String.split(name, " ")) + 1) + item_contains_full_term(name, item)) / String.length(name)
            Map.update(acc, found_item, length, &(&1 + length))
          end)
          |> Enum.sort_by(fn {_, score} -> score end, :desc)

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

  defp item_contains_full_term(name, term) do
    cond do
      name =~ term -> 5
      true -> 0
    end
  end

  defp parse_item(value) do
    Regex.scan(~r/[a-zA-Z]+/, value)
    |> Enum.map(fn [i] -> i end)
    |> Enum.reject(&(&1 == "" || &1 == nil))
    |> Enum.sort()
    |> Enum.dedup()
  end
end
