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

    slug =
      recipe.title
      |> String.downcase()
      |> String.replace(" ", "-")

    meta_attrs = %{
      title: recipe.title,
      description: recipe.description,
      url: Path.join("https://www.relaxanddine.com", ~p"/recipes/#{recipe.id}/#{slug}"),
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
      |> Recipes.delete_recipe()

    {
      :noreply,
      redirect(socket, to: ~p"/recipes")
    }
  end

  @impl true
  def handle_event("create_ingredient", %{"id" => id}, socket) do
    recipe = Recipes.get_recipe!(id)

    case Recipes.get_or_create_ingredient_from_recipe(recipe) do
      {:ok, ingredient} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ingredient '#{ingredient.name}' created from recipe")
         |> redirect(to: ~p"/ingredients/#{ingredient.id}/#{String.downcase(ingredient.name)}")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create ingredient: #{inspect(changeset.errors)}")}
    end
  end

  defp page_title(:show), do: "Show Recipe"
  defp page_title(:edit), do: "Edit Recipe"
end
