defmodule RelaxirWeb.RecipeView do
  use RelaxirWeb, :view

  def categories_input(form, field, _opts \\ []) do
    categories = Phoenix.HTML.Form.input_value(form, field)
    Phoenix.HTML.Form.text_input(form, field, value: categories_to_text(categories))
  end

  def categories_to_text(categories) do
    categories
    |> Enum.map(fn i -> i.name end)
    |> Enum.join(", ")
  end

  def ingredients_input(form, field, _opts \\ []) do
    ingredients = Phoenix.HTML.Form.input_value(form, field)
    Phoenix.HTML.Form.textarea(form, field, value: ingredients_to_text(ingredients))
  end

  def ingredients_to_text(ingredients) do
    ingredients
    |> Enum.map(fn i -> i.name end)
    |> Enum.join("\r\n")
  end

  def render_markdown(text) do
    case text do
      nil -> ""
      _ -> raw(Earmark.as_html!(text))
    end
  end
end
