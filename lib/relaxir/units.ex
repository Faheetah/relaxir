defmodule Relaxir.Units do
  @moduledoc """
  The Units context.
  Handles unit conversion and parsing using the new Unit library.
  The unit library is the sole source of truth for units.
  """

  alias Unit, as: UnitLib

  @doc """
  Gets the unit name from a unit struct.
  """
  def get_unit_name(%{singular: singular}) when is_binary(singular) do
    singular
  end

  def get_unit_name(_), do: nil

  @doc """
  Creates a new unit in the database.
  """
  def create_unit(attrs) do
    alias Relaxir.Repo
    alias Relaxir.Units.Unit, as: DbUnit

    name = Map.get(attrs, :name, "")
    abbreviation = Map.get(attrs, :abbreviation, "")

    # Store the unit with both singular and plural forms as keys
    singular_name = Inflex.singularize(name)
    singular_abbreviation = Inflex.singularize(abbreviation)

    # Create a single database record for the unit
    unit_attrs = %{name: singular_name, abbreviation: singular_abbreviation}

    %DbUnit{}
    |> DbUnit.changeset(unit_attrs)
    |> Repo.insert()
  end

  @doc """
  Converts a unit from the new Unit library to a database unit record.
  """
  def unit_to_db_unit(%{__struct__: _unit_type, value: _value} = unit) do
    # Get the unit name from the unit struct
    unit_name = get_unit_name(unit)

    if unit_name do
      get_unit_by_name(unit_name)
    else
      nil
    end
  end

  def unit_to_db_unit(:error), do: nil
  def unit_to_db_unit(_), do: nil

  @doc """
  Converts a database unit record to a unit from the new Unit library.
  """
  def db_unit_to_unit(%{name: name}, value) do
    # Try to create a unit library unit based on the database unit name
    # Use the unit library's parsing functions to create the appropriate unit
    case UnitLib.parse("#{value} #{name}") do
      {unit, _} -> unit
      _ -> nil
    end
  end

  def db_unit_to_unit(_, _), do: nil

  @doc """
  Gets a unit by name from the database or unit library.
  """
  def get_unit_by_name(name) do
    import Ecto.Query
    alias Relaxir.Repo
    alias Relaxir.Units.Unit, as: DbUnit

    normalized_name = String.downcase(name)
    singular = Inflex.singularize(normalized_name)
    plural = Inflex.pluralize(normalized_name)

    # Try to get an existing unit from the database first
    db_unit =
      DbUnit
      |> where([u], u.name in [^singular, ^plural] or u.abbreviation in [^singular, ^plural])
      |> Repo.one()

    case db_unit do
      nil ->
        # Try to parse the unit name with the unit library to see if it's valid
        # If it is, create a mock database unit record
        case UnitLib.parse("1 #{normalized_name}") do
          {unit, _} ->
            # Get the unit name from the parsed unit
            unit_name = get_unit_name(unit)

            if unit_name do
              %{name: unit_name, abbreviation: normalized_name}
            else
              nil
            end

          _ ->
            # For custom unit names that haven't been created, return nil
            nil
        end

      unit ->
        unit
    end
  end

  @doc """
  Parses a string into a unit using the new Unit library.
  """
  def parse_unit_string(string) do
    case UnitLib.parse(string) do
      {:error, reason} -> {:error, reason}
      {unit, rest} -> {:ok, unit, rest}
    end
  end

  @doc """
  Parses a string into a weight unit using the new Unit library.
  """
  def parse_unit_string_weight(string) do
    case UnitLib.parse_weight(string) do
      {:error, reason} -> {:error, reason}
      {unit, rest} -> {:ok, unit, rest}
    end
  end

  @doc """
  Parses a string into a volume unit using the new Unit library.
  """
  def parse_unit_string_volume(string) do
    case UnitLib.parse_volume(string) do
      {:error, reason} -> {:error, reason}
      {unit, rest} -> {:ok, unit, rest}
    end
  end

  @doc """
  Converts a unit to its string representation.
  """
  def unit_to_string(unit) do
    UnitLib.to_string(unit)
  end

  @doc """
  Adds two units together.
  """
  def add_units(unit1, unit2) do
    UnitLib.add(unit1, unit2)
  end

  @doc """
  Converts a unit to another unit type.
  """
  def convert_unit(unit, target_unit_type) do
    UnitLib.convert(unit, target_unit_type)
  end

  @doc """
  Lists all units from the database.
  """
  def list_units() do
    alias Relaxir.Repo
    alias Relaxir.Units.Unit, as: DbUnit

    Repo.all(DbUnit)
  end
end
