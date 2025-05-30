defmodule RelaxirWeb.IngredientLive.Show do
  use RelaxirWeb, :live_view

  alias Relaxir.Ingredients

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    ingredient = Ingredients.get_ingredient!(id)
    recipes = Ingredients.get_recipes_for_ingredient(ingredient)
    slug =
      ingredient.name
      |> String.downcase
      |> String.replace(" ", "-")

    meta_attrs = %{
      title: ingredient.name,
      description: ingredient.description,
      url: Path.join("https://www.relaxanddine.com", ~p"/ingredients/#{ingredient.id}/#{slug}")
    }

    {
      :noreply,
      socket
      |> assign(:page_title, "Show Ingredient")
      |> assign(:ingredient, ingredient)
      |> assign(:recipes, recipes)
      |> assign(:meta_attrs, meta_attrs)
    }
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _recipe} =
      Recipes.get_recipe!(id)
      |> Recipes.delete_recipe

    {
      :noreply,
      redirect(socket, to: ~p"/recipes")
    }
  end
end
