defmodule RelaxirWeb.RecipeView do
  use RelaxirWeb, :view

  def categories_input(form, field, _opts \\ []) do
    categories = Phoenix.HTML.Form.input_value(form, field)
    Phoenix.HTML.Form.text_input(form, field, value: format_names_to_text(categories, ", "))
  end

  def ingredients_input(form, field, _opts \\ []) do
    ingredients =
      Phoenix.HTML.Form.input_value(form, field)
      |> format_ingredient_fields()
      |> format_names_to_text("\n")
    Phoenix.HTML.Form.textarea(form, field, value: ingredients)
  end

  def ingredients_output(recipe_ingredient) do
    unit = recipe_ingredient.unit
    amount = recipe_ingredient.amount
    note = recipe_ingredient.note

    unit = case unit do
      nil -> nil
      unit when amount == 1 -> unit.singular
      unit when amount > 1 -> unit.plural
    end

    [amount, unit, recipe_ingredient.ingredient.name]
    |> Enum.reject(&(is_nil(&1)))
    |> Enum.join(" ")
    |> (fn i ->
      cond do
        is_nil(note) -> i
        true -> "#{i}, #{note}"
      end
    end).()
  end

  def format_ingredient_fields(fields) do
    fields
    |> Enum.map(fn f ->
      %{name: f.ingredient.name}
    end)
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
