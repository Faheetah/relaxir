defmodule RelaxirWeb.RecipeParser do
  def parse_attrs(attrs) do
    attrs
    |> split_field("categories", ",")
    |> split_field("ingredients", "\n")
    |> parse_ingredients()
  end

  def split_field(attrs, name, separator) do
    field =
      (attrs[name] || "")
      |> String.split(separator)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    Map.put(attrs, name, field)
  end

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

    Map.put(attrs, "ingredients", ingredients)
  end

  def extract_ingredient_fields(ingredient) do
    {:ok, %{name: ingredient}}
    |> extract_ingredient_amount
    |> extract_ingredient_note
  end

  def extract_ingredient_amount({:ok, ingredient}) do
    case String.split(ingredient.name) do
      [whole, fraction, unit | name] ->
        cond do
          Float.parse(fraction) != :error and Float.parse(whole) != :error and hd(Tuple.to_list(Float.parse(fraction))) ->
            parsed_amount = hd(Tuple.to_list(Float.parse(whole))) + parse_amount(fraction)
            build_ingredient(parsed_amount, ingredient: ingredient, unit: unit, name: name)

          true ->
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

  def parse_amount(amount) do
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

  def extract_ingredient_note({:ok, ingredient}) do
    name =
      ingredient.name
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    case name do
      [name, note] -> {:ok, Map.merge(ingredient, %{name: name, note: note})}
      _ -> {:ok, ingredient}
    end
  end
end
