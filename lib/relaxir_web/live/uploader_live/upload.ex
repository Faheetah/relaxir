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
      :ok = resize(path, dest, "640", "480", "full")
      :ok = resize(path, dest, "400", "400", "thumbnail")

      socket.assigns.recipe
      |> String.to_integer()
      |> Relaxir.Recipes.get_recipe!()
      |> Relaxir.Recipes.Recipe.changeset(%{"image_filename" => Path.basename(path)})
      |> Relaxir.Repo.update()
    end)

    {
      :noreply,
      redirect(socket, to: Routes.recipe_path(socket, :show, socket.assigns.recipe))
    }
  end

  defp resize(path, dest, width, height, suffix) do
    {_, 0} = System.cmd("gm", [
      "convert",
      path,
      "-resize", "#{width}x#{height}^",
      "-gravity", "Center",
      "-crop", "#{width}x#{height}+0+0",
      "+profile", "'*'",
      "-compress", "JPEG",
      Path.join(dest, "#{Path.basename(path)}-#{suffix}.jpg")
    ])
    :ok =
      Path.join(dest, "#{Path.basename(path)}-#{suffix}.jpg")
      |> File.chmod(0o644)
  end
end
