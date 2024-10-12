defmodule RelaxirWeb.RecipeLive.Show do
  use RelaxirWeb, :live_view

  alias Relaxir.Recipes

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    recipe = Recipes.get_recipe!(id)

    meta_attrs = %{
      title: recipe.title,
      description: recipe.description,
      url: Path.join("https://www.relaxanddine.com", ~p"/recipes/#{recipe}"),
      image: get_upload_path(recipe.image_filename)
    }

    {
      :noreply,
      socket
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:recipe, recipe)
      |> assign(:meta_attrs, meta_attrs)
    }
  end

  defp get_upload_path(nil), do: "/images/default-full.jpg"
  defp get_upload_path(file), do: "/uploads/#{file}-full.jpg"

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

  defp page_title(:show), do: "Show Recipe"
  defp page_title(:edit), do: "Edit Recipe"
end
