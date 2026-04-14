defmodule Relaxir.Ingredients.Parser do
  @moduledoc """
  Parser for recipe ingredients that uses the new Unit library for parsing
  and maintains backward compatibility with existing database units.
  """

  @doc """
  Parses a list of ingredients using the new Unit library.
  """
  def parse_ingredients(attrs) do
    ingredients =
      attrs["ingredients"]
      |> Enum.map(&parse_ingredient/1)
      |> Enum.reject(&is_nil/1)

    Map.put(attrs, "ingredients", ingredients)
  end

  @doc """
  Maps recipe ingredient fields using the new Unit library.
  """
  def map_recipe_ingredient_fields(attrs, units) do
    amount = Map.get(attrs, :amount)
    unit_name = Map.get(attrs, :unit)

    if amount == nil || unit_name == nil do
      attrs
    else
      find_unit(units, unit_name)
      |> map_unit(attrs, unit_name, amount)
    end
  end

  defp singularize_unit(unit, name) do
    singularized = Inflex.singularize(name)
    singularized == unit.name or singularized == unit.abbreviation
  end

  defp find_unit(units, unit_name) do
    {:ok, Enum.find(units, &singularize_unit(&1, unit_name))}
  end

  defp map_unit({:ok, nil}, attrs, unit_name, amount) do
    if Map.get(attrs, :name) do
      attrs
      |> Map.merge(%{
        name:
          [unit_name, attrs.name]
          |> Enum.join(" ")
          |> String.trim(),
        amount: amount
      })
      |> Map.delete(:unit)
    else
      Map.merge(attrs, %{amount: amount})
    end
  end

  defp map_unit({:ok, unit}, attrs, _unit_name, amount) do
    Map.merge(attrs, %{amount: amount, unit_id: unit.id})
  end

  defp parse_ingredient(ingredient_string) do
    # Try to parse using the new Unit library first
    case Relaxir.Units.parse_unit_string(ingredient_string) do
      {:ok, unit, rest} ->
        # Successfully parsed with Unit library
        build_ingredient_from_unit(unit, rest)

      {:error, _reason} ->
        # Return nil for unparseable ingredients
        nil
    end
  end

  defp build_ingredient_from_unit(unit, rest) do
    # Clean up the rest of the string
    cleaned_rest = String.trim(rest)

    # Extract note if present (everything after the first comma)
    case String.split(cleaned_rest, ",", parts: 2) |> Enum.map(&String.trim/1) do
      [ingredient_name] ->
        # No note present
        %{
          amount: unit.value,
          unit: (unit.value == 1.0 && unit.singular) || unit.plural,
          name: ingredient_name
        }

      [ingredient_name, note] ->
        # Note present
        %{
          amount: unit.value,
          unit: (unit.value == 1.0 && unit.singular) || unit.plural,
          name: ingredient_name,
          note: note
        }
    end
  end
end
