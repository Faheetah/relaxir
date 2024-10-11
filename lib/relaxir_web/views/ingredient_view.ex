defmodule RelaxirWeb.IngredientView do
  use RelaxirWeb, :view

  # sobelow_skip ["XSS.Raw"]
  def render_markdown(text) do
    case text do
      nil -> ""
      _ -> raw(Earmark.as_html!(text))
    end
  end

  def parent_ingredient_input(form, field, opts \\ [])
  def parent_ingredient_input(%{data: %{parent_ingredient: %{name: name}}} = form, field, opts) do
    Phoenix.HTML.Form.text_input(form, field, Keyword.merge(opts, [value: name]))
  end
  def parent_ingredient_input(form, field, opts) do
    Phoenix.HTML.Form.text_input(form, field, opts)
  end

  def source_recipe_input(form, field, opts \\ [])
  def source_recipe_input(%{data: %{source_recipe_id: nil}} = form, field, opts) do
    Phoenix.HTML.Form.text_input(form, field, opts)
  end
  def source_recipe_input(%{data: %{source_recipe_id: id}} = form, field, opts) do
    path = RelaxirWeb.Router.Helpers.recipe_url(RelaxirWeb.Endpoint, :show, id)
    Phoenix.HTML.Form.text_input(form, field, Keyword.merge(opts, [value: path]))
  end
  def source_recipe_input(form, field, opts) do
    Phoenix.HTML.Form.text_input(form, field, opts)
  end
end
