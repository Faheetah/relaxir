defmodule RelaxirWeb.CategoryLive.Show do
  use RelaxirWeb, :live_view

  alias Relaxir.Categories
  alias Relaxir.Categories.Category

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id, "name" => name}, _, socket) do
    (Categories.get_category!(id) || %Category{name: name, recipes: [], recipe_categories: []})
    |> Categories.reject_unpublished_recipes()
    |> get_recipes(socket)
  end

  def handle_params(%{"name" => name}, _, socket) do
    (Categories.get_category_by_name!(name) || %Category{name: name, recipes: [], recipe_categories: []})
    |> Categories.reject_unpublished_recipes()
    |> get_recipes(socket)
  end

  defp get_recipes(category, socket) do
    recipes =
      if category.recipes != [] do
        Categories.latest_recipes_for_category(category, category.id)
      else
        []
      end

    {
      :noreply,
      socket
      |> assign(:category, category)
      |> assign(:recipes, recipes)
    }
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _recipe} =
      Categories.get_category!(id)
      |> Categories.delete_category

    {:noreply, redirect(socket, to: ~p"/categories/all")}
  end
end
