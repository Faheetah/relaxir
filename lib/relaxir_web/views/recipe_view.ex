defmodule RelaxirWeb.RecipeView do
  use RelaxirWeb, :view

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
    whole_number = floor(amount)

    adjustment = case (amount - floor(amount)) do
      0.0 -> 1
      0 -> 1
      i -> i
    end

    fraction = floor(1 / adjustment)

    [whole_number, fraction]
    |> case do
      [0, fraction] -> "1/#{fraction}"
      [number, 1] -> number
      [number, fraction] -> "#{number} 1/#{fraction}"
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
