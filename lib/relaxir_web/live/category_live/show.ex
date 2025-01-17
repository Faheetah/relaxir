defmodule RelaxirWeb.CategoryLive.Show do
  use RelaxirWeb, :live_view

  alias Relaxir.Categories

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"name" => name}, _, socket) do
    category = Categories.get_category_by_name!(name)
    recipes = Categories.latest_recipes_for_category(category, 24)

    {
      :noreply,
      socket
      |> assign(:category, category)
      |> assign(:recipes, recipes)
    }
  end
end
