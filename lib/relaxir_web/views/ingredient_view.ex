defmodule RelaxirWeb.IngredientView do
  use RelaxirWeb, :view

  # sobelow_skip ["XSS.Raw"]
  def render_markdown(text) do
    case text do
      nil -> ""
      _ -> raw(Earmark.as_html!(text))
    end
  end

  def parent_ingredient_input(form = %{data: %{parent_ingredient: %{name: name}}}, field, opts) do
    Phoenix.HTML.Form.text_input(form, field, Keyword.merge(opts, [value: name]))
  end
  def parent_ingredient_input(form, field, opts \\ []) do
    Phoenix.HTML.Form.text_input(form, field, opts)
  end
end
