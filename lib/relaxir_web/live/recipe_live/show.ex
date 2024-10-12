defmodule RelaxirWeb.RecipeLive.Show do
  use RelaxirWeb, :live_view

  alias Relaxir.Recipes

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:recipe, Recipes.get_recipe!(id))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _recipe} =
      Recipes.get_recipe!(id)
      |> Recipes.delete_recipe

    {:noreply, push_navigate(socket, to: ~p"/recipes")}
  end

  defp page_title(:show), do: "Show Recipe"
  defp page_title(:edit), do: "Edit Recipe"
end
