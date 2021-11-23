defmodule RelaxirWeb.UploadLive do
  use RelaxirWeb, :live_view

  @impl Phoenix.LiveView
  def mount(%{"id" => recipe_id} = params, _session, socket) do
    {:ok,
    socket
    |> assign(:uploaded_files, [])
    |> assign(:recipe, recipe_id)
    |> allow_upload(:picture, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :picture, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :picture, fn %{path: path}, _entry ->
        dest = Path.join([:code.priv_dir(:relaxir), "static", "uploads", Path.basename(path)])
        File.cp!(path, dest)

        socket.assigns.recipe
        |> String.to_integer()
        |> Relaxir.Recipes.get_recipe!()
        |> Relaxir.Recipes.update_recipe(%{"image_filename" => Path.basename(dest)})
      end)

    {
      :noreply,
      redirect(socket, to: Routes.recipe_path(socket, :show, socket.assigns.recipe))
      # update(socket, :uploaded_files, &(&1 ++ uploaded_files))
    }
  end
end
