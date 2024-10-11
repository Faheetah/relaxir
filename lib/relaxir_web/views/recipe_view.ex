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

  def categories_input(form, field, opts \\ []) do
    categories = Phoenix.HTML.Form.input_value(form, field)
    Phoenix.HTML.Form.text_input(form, field, Keyword.merge(opts, [value: format_names_to_text(categories, ", ")]))
  end

  def ingredients_input(form, field, ingredients, opts \\ []) do
    ingredients = Enum.map_join(ingredients, &ingredients_output/1, "\n")

    Phoenix.HTML.Form.textarea(form, field, Keyword.merge(opts, [value: ingredients]))
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

    ingredient_name = inflex_ingredient(recipe_ingredient.ingredient, amount, unit)

    [parse_fraction(amount), unit, ingredient_name]
    |> Enum.reject(&is_nil(&1))
    |> Enum.join(" ")
    |> String.trim()
    |> maybe_add_note(note)
  end

  def inflex_ingredient(%{singular: ""} = ingredient, _amount, _unit), do: ingredient.name
  def inflex_ingredient(ingredient, amount, unit) when amount <= 1 and unit == "", do: ingredient.singular
  def inflex_ingredient(ingredient, _amount, _unit), do: ingredient.name

  def maybe_add_note(i, nil), do: i
  def maybe_add_note(i, note), do: "#{i}, #{note}"

  def parse_fraction(nil), do: nil

  # What does this do lol?
  # Looks like it turns a float into a human readable fraction
  def parse_fraction(amount) do
    # covers up to 1..100/1..100 reliably
    # can possibly cover up to 1/999999 reasonably well
    # reducing this can improve performance in case of DoS since :timer.tc 1/999999 = ~600ms
    denominator =
      1..9_999_999
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
    Enum.map_join(items, fn i ->
      case i do
        %{name: name} -> name
        _ -> i
      end
    end, separator)
  end

  # sobelow_skip ["XSS.Raw"]
  def render_markdown(text) do
    case text do
      nil -> ""
      _ -> Earmark.as_html!(text)
    end
  end

  def format_month(month) do
    months = %{1 => "Jan", 2 => "Feb", 3 => "Mar", 4 => "Apr", 5 => "May", 6 => "Jun", 7 => "Jul", 8 => "Aug", 9 => "Sep", 10 => "Oct", 11 => "Nov", 12 => "Dec"}
    months[month]
  end
end
