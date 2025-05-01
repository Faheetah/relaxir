defmodule RelaxirWeb.RecipeLive.Upload do
  use RelaxirWeb, :live_view

  alias Relaxir.Recipes

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  # Comes from RelaxirWeb.UploadLive as a callback to update the recipe. This was passed to it in show.html.heex.
  @impl true
  def handle_params(%{"id" => id, "image_filename" => image_filename}, _what, socket) do
    recipe = Recipes.get_recipe!(id)
    Recipes.update_image_filename(recipe, image_filename)

    {
      :noreply,
      push_patch(socket, to: ~p"/recipes/#{id}")
    }
  end
end
