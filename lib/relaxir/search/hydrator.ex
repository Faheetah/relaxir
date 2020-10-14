defmodule Relaxir.Search.Hydrator do
  use Task

  require Logger
  alias Relaxir.Search

  def start_link([repo: repo, tables: tables]) do
    Task.start_link(__MODULE__, :start_hydrate, [repo, tables])
  end

  def start_hydrate(repo, tables) do
    Enum.map(tables, fn {table, indexed_field, fields} ->
      Task.start_link(fn -> hydrate(repo, table, indexed_field, fields) end)
    end)
  end

  def hydrate(repo, table, indexed_field, fields) do
    Logger.info "#{table}.#{indexed_field} hydration start"
    table_name = Search.atom_from_module(table, indexed_field)

    table
    |> repo.stream
    |> Enum.map(fn record ->
      {Map.get(record, indexed_field), Enum.map(fields, fn f -> Map.get(record, f) end)}
    end)
    |> Enum.sort_by(fn {indexed_field, _} -> indexed_field end)
    |> Enum.dedup_by(fn {indexed_field, _} -> indexed_field end)
    |> Enum.each(&Search.insert_item(table_name, &1))
    Logger.info "#{table}.#{indexed_field} hydrated"
  end
end
