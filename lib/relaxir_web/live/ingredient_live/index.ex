defmodule RelaxirWeb.IngredientLive.Index do
  use RelaxirWeb, :live_view

  alias Relaxir.Ingredients

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :ingredients, [])}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    ingredients = Ingredients.list_ingredients()

    {
      :noreply,
      assign(socket, :ingredients, ingredients)
    }
  end
end
