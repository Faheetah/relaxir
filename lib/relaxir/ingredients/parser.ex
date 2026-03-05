defmodule Relaxir.Ingredients.Parser do
  def parse_ingredients(attrs) do
    ingredients =
      attrs["ingredients"]
      |> Enum.map(&extract_ingredient_fields/1)
      |> Enum.map(fn ingredient ->
        case ingredient do
          {:ok, ingredient} -> ingredient
          {:error, error} -> {:error, error}
          [] -> []
        end
      end)
      |> Enum.sort_by(fn i -> Map.get(i, :order) end)

    Map.put(attrs, "ingredients", ingredients)
  end

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

  defp map_unit({:error, error}, _attrs, _unit_name, _amount), do: {:error, error}

  defp extract_ingredient_fields(ingredient) do
    {:ok, %{name: ingredient}}
    |> extract_ingredient_note
    |> extract_ingredient_amount
  end

  defp extract_ingredient_amount({:ok, ingredient}) do
    case String.split(ingredient.name) do
      [whole, fraction, unit | name] ->
        if Float.parse(fraction) != :error and Float.parse(whole) != :error and hd(Tuple.to_list(Float.parse(fraction))) do
          parsed_amount = hd(Tuple.to_list(Float.parse(whole))) + parse_amount(fraction)
          build_ingredient(parsed_amount, ingredient: ingredient, unit: unit, name: name)
        else
          build_ingredient(parse_amount(whole), ingredient: ingredient, unit: fraction, name: [unit | name])
        end

      [amount, unit | name] ->
        build_ingredient(parse_amount(amount), ingredient: ingredient, unit: unit, name: name)

      _ ->
        {:ok, ingredient}
    end
  end

  defp build_ingredient(:error, ingredient: ingredient, unit: _unit, name: _name) do
    {:ok, ingredient}
  end

  defp build_ingredient(amount, ingredient: ingredient, unit: unit, name: name) do
    {:ok,
     Map.merge(
       ingredient,
       %{
         amount: amount,
         unit: unit,
         name: Enum.join(name, " ")
       }
     )}
  end

  defp parse_amount(amount) do
    divisor =
      amount
      |> String.split("/")
      |> Enum.map(&Integer.parse/1)

    case divisor do
      [:error | _] -> :error
      [_, :error] -> :error
      [{amt, _}] -> amt
      [{numerator, _}, {denominator, _}] -> numerator / denominator
    end
  end

  defp extract_ingredient_note({:ok, ingredient}) do
    [name | note] = String.split(ingredient.name, ",")

    note =
      note
      |> Enum.reject(&(&1 == nil))
      |> Enum.join(",")
      |> String.trim()

    {
      :ok,
      Map.merge(
        ingredient,
        case note do
          "" -> %{name: String.trim(name)}
          _ -> %{name: String.trim(name), note: note}
        end
      )
    }
  end
end
