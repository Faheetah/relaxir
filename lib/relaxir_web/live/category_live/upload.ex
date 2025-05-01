defmodule RelaxirWeb.CategoryLive.Upload do
  use RelaxirWeb, :live_view

  alias Relaxir.Categories

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  # Comes from RelaxirWeb.UploadLive as a callback to update the category. This was passed to it in show.html.heex.
  @impl true
  def handle_params(%{"id" => id, "image_filename" => image_filename}, _what, socket) do
    category = Categories.get_category!(id)
    Categories.update_image_filename(category, image_filename)

    {
      :noreply,
      push_patch(socket, to: ~p"/categories/#{category.name}")
    }
  end
end
