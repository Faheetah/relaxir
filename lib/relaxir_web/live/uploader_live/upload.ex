defmodule RelaxirWeb.UploadLive do
  use RelaxirWeb, :live_view

  @impl Phoenix.LiveView
  def mount(%{"id" => recipe_id} = _params, _session, socket) do
    {:ok,
    socket
    |> assign(:uploaded_files, [])
    |> assign(:recipe, recipe_id)
    |> allow_upload(:picture, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :picture, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", _params, socket) do
    consume_uploaded_entries(socket, :picture, fn %{path: path}, _entry ->
      dest = Application.fetch_env!(:relaxir, RelaxirWeb.UploadLive)[:dest]
      File.cp!(path, Path.join(dest, Path.basename(path)))

      socket.assigns.recipe
      |> String.to_integer()
      |> Relaxir.Recipes.get_recipe!()
      |> Relaxir.Recipes.update_recipe(%{"image_filename" => Path.basename(path)})
    end)

    {
      :noreply,
      redirect(socket, to: Routes.recipe_path(socket, :show, socket.assigns.recipe))
    }
  end
end
