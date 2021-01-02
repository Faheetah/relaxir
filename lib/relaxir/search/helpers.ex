defmodule Relaxir.Search.Helpers do
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

  def new_atom_from_module(module, name) do
    parse_atom_from_module(module, name)
    |> String.to_atom()
  end

  def parse_atom_from_module(module, name) do
    module
    |> Atom.to_string()
    |> String.split(".")
    |> Enum.map(&String.downcase/1)
    |> List.delete_at(0)
    |> Enum.concat([Atom.to_string(name)])
    |> Enum.join("_")
  end
end
