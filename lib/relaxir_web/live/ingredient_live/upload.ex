defmodule RelaxirWeb.IngredientLive.Upload do
  use RelaxirWeb, :live_view

  alias Relaxir.Ingredients

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  # Comes from RelaxirWeb.UploadLive as a callback to update the ingredient. This was passed to it in show.html.heex.
  @impl true
  def handle_params(%{"id" => id, "image_filename" => image_filename}, _what, socket) do
    ingredient = Ingredients.get_ingredient!(id)
    Ingredients.update_image_filename(ingredient, image_filename)

    {
      :noreply,
      push_patch(socket, to: ~p"/ingredients/#{ingredient.id}/#{ingredient.name}")
    }
  end
end
