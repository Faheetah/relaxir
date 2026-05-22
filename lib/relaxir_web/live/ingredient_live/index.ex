defmodule RelaxirWeb.IngredientLive.Index do
  use RelaxirWeb, :live_view

  alias Relaxir.Ingredients

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:ingredients, [])
     |> assign(:ingredient_recipes, %{})}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    ingredients = Ingredients.list_pure_ingredients()

    ingredient_ids = Enum.map(ingredients, & &1.id)
    ingredient_recipes = Ingredients.get_recipes_for_ingredients(ingredient_ids)

    {
      :noreply,
      socket
      |> assign(:ingredients, ingredients)
      |> assign(:ingredient_recipes, ingredient_recipes)
    }
  end
end
