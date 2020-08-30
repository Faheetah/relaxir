defmodule RelaxirWeb.IngredientView do
  use RelaxirWeb, :view

  def render_markdown(text) do
    case text do
      nil -> ""
      _ -> raw(Earmark.as_html!(text))
    end
  end
end
