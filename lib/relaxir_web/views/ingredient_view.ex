defmodule RelaxirWeb.IngredientView do
  use RelaxirWeb, :view

  # sobelow_skip ["XSS.Raw"]
  def render_markdown(text) do
    case text do
      nil -> ""
      _ -> raw(Earmark.as_html!(text))
    end
  end
end
