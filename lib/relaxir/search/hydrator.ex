defmodule Relaxir.Search.Hydrator do
  use Task
  import Ecto.Query

  require Logger
  alias Invert.Server
  alias Invert.Helpers

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
    table_name = Helpers.atom_from_module(table, indexed_field)

    query = from(table, order_by: [^indexed_field])
    chunk_size = 5000

    Stream.resource(
      fn -> 0 end,
      fn
        :stop -> {:halt, :stop}
        offset ->
          rows =
            repo.all(from(query, limit: ^chunk_size, offset: ^offset))
            if Enum.count(rows) < chunk_size do
              {rows, :stop}
            else
              {rows, offset + chunk_size}
            end
          end,
          fn _ -> :ok end
    )
    |> Stream.map(fn record ->
      {Map.get(record, indexed_field), Enum.map(fields, fn f -> Map.get(record, f) end)}
    end)
    |> Enum.each(&GenServer.call(Server, {:set, table_name, &1}, 500))
    Logger.info "#{table}.#{indexed_field} hydrated"
  end
end
