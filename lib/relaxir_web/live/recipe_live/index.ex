defmodule RelaxirWeb.RecipeLive.Index do
  use RelaxirWeb, :live_view

  alias Relaxir.Recipes
  alias Relaxir.Recipes.Recipe

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :recipes, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    recipes = Recipes.list_recipes(socket.assigns.current_user)

    {
      :noreply,
      socket
      |> apply_action(socket.assigns.live_action, params)
      |> stream(:recipes, recipes)
    }
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Recipe")
    |> assign(:recipe, Recipes.get_recipe!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Recipe")
    |> assign(:recipe, %Recipe{recipe_ingredients: [], categories: []})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Recipes")
    |> assign(:recipe, nil)
  end

  @impl true
  def handle_info({RelaxirWeb.RecipeLive.FormComponent, {:saved, recipe}}, socket) do
    {:noreply, stream_insert(socket, :recipes, recipe)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    recipe = Recipes.get_recipe!(id)
    {:ok, _} = Recipes.delete_recipe(recipe)

    {:noreply, stream_delete(socket, :recipes, recipe)}
  end
end
