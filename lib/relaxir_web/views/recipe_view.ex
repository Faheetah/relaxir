defmodule RelaxirWeb.RecipeView do
  use RelaxirWeb, :view

  def categories_input(form, field, _opts \\ []) do
    categories = Phoenix.HTML.Form.input_value(form, field)
    Phoenix.HTML.Form.text_input(form, field, value: format_names_to_text(categories, ", "))
  end

  def ingredients_input(form, field, _opts \\ []) do
    ingredients = Phoenix.HTML.Form.input_value(form, field)
    Phoenix.HTML.Form.textarea(form, field, value: format_names_to_text(ingredients, "\n"))
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
