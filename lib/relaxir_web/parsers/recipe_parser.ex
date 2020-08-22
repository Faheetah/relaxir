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
      |> Enum.map(&%{name: &1})

    Map.put(attrs, "ingredients", ingredients)
  end

  def extract_ingredient_fields(ingredient) do
    {:ok, %{name: ingredient}}
    |> extract_ingredient_amount
    |> extract_ingredient_note
  end

  def extract_ingredient_amount({:ok, ingredient}) do
    case String.split(ingredient.name) do
      [amount, unit | name] ->
        parsed_amount = parse_amount(amount)
        case parsed_amount do
          :error ->
            {:ok, ingredient}

          _ ->
            {:ok,
             Map.merge(
               ingredient,
               %{
                 amount: parsed_amount,
                 unit: unit,
                 name: Enum.join(name)
               }
             )}
        end

      _ ->
        {:ok, ingredient}
    end
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
    name = ingredient.name
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    case name do
      [name, note] -> {:ok, Map.merge(ingredient, %{name: name, note: note})}
      _ -> {:ok, ingredient}
    end
  end
end
