defmodule RelaxirWeb.RecipeView do
  use RelaxirWeb, :view

  def boolean_input(form, field, _opts \\ []) do
    value =
      case Phoenix.HTML.Form.input_value(form, field) do
        true -> "true"
        _ -> "false"
      end

    Phoenix.HTML.Form.checkbox(form, field, value: value)
  end

  def categories_input(form, field, _opts \\ []) do
    categories = Phoenix.HTML.Form.input_value(form, field)
    Phoenix.HTML.Form.text_input(form, field, value: format_names_to_text(categories, ", "))
  end

  def ingredients_input(form, field, ingredients, _opts \\ []) do
    ingredients =
      ingredients
      |> Enum.map(&ingredients_output/1)
      |> Enum.join("\n")

    Phoenix.HTML.Form.textarea(form, field, value: ingredients)
  end

  def ingredients_output(recipe_ingredient) do
    unit = Map.get(recipe_ingredient, :unit)
    amount = Map.get(recipe_ingredient, :amount)
    note = Map.get(recipe_ingredient, :note)

    unit =
      cond do
        unit == nil -> nil
        amount > 1 -> Inflex.pluralize(unit.name)
        true -> Inflex.singularize(unit.name)
      end

    [parse_fraction(amount), unit, recipe_ingredient.ingredient.name]
    |> Enum.reject(&is_nil(&1))
    |> Enum.join(" ")
    |> String.trim
    |> (fn i ->
          cond do
            is_nil(note) -> i
            true -> "#{i}, #{note}"
          end
        end).()
  end

  def parse_fraction(nil), do: nil

  def parse_fraction(amount) do
    denominator =
      # covers up to 1..100/1..100 reliably
      # can possibly cover up to 1/999999 reasonably well
      # reducing this can improve performance in case of DoS since :timer.tc 1/999999 = ~600ms
      1..9999999
      |> Enum.find(1, fn f ->
        # amount / 1 to force float, in case of amount = 1
        Float.floor(f * (amount / 1)) == f * amount
      end)

    numerator = trunc(amount * denominator)
    whole = trunc((numerator - rem(numerator, denominator)) / denominator)
    gcd = Integer.gcd(numerator, denominator)

    [whole, trunc(rem(numerator, denominator) / gcd), trunc(denominator / gcd)]
    |> case do
      [0, n, d] when n > 0 and d > 0 -> "#{n}/#{d}"
      [w, _, 1] -> w
      [w, n, d] -> "#{w} #{n}/#{d}"
    end
  end

  def format_ingredient_fields(fields) do
    fields
    |> Enum.map(&ingredients_output/1)
  end

  def format_names_to_text(items, separator) do
    items
    |> Enum.map(fn i ->
      case i do
        %{name: name} -> name
        _ -> i
      end
    end)
    |> Enum.join(separator)
  end

  def render_markdown(text) do
    case text do
      nil -> ""
      _ -> raw(Earmark.as_html!(text))
    end
  end
end
