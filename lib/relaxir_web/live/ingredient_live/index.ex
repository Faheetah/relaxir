defmodule RelaxirWeb.IngredientLive.Index do
  use RelaxirWeb, :live_view

  alias Relaxir.Ingredients
  alias Relaxir.Ingredients.Ingredient

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:ingredients, [])
     |> assign(:ingredient_recipes, %{})}
  end

  @impl true
  def handle_params(params, _url, socket) do
    ingredients = Ingredients.list_pure_ingredients()

    ingredient_ids = Enum.map(ingredients, & &1.id)
    ingredient_recipes = Ingredients.get_recipes_for_ingredients(ingredient_ids)

    {
      :noreply,
      socket
      |> apply_action(socket.assigns.live_action, params)
      |> assign(:ingredients, ingredients)
      |> assign(:ingredient_recipes, ingredient_recipes)
    }
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Ingredient")
    |> assign(:ingredient, %Ingredient{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Ingredients")
    |> assign(:ingredient, nil)
  end

  @impl true
  def handle_info({RelaxirWeb.IngredientLive.FormComponent, {:saved, ingredient}}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/ingredients/#{ingredient.id}/#{ingredient.name}")}
  end
end
