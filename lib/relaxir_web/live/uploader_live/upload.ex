defmodule RelaxirWeb.UploadLive do
  use RelaxirWeb, :live_view

  @impl Phoenix.LiveView
  def mount(%{"path" => upload_image_filename, "redirect" => upload_redirect}, _session, socket) do
    {
      :ok,
      socket
      |> assign(:upload_image_filename, upload_image_filename)
      |> assign(:upload_redirect, upload_redirect)
      |> assign(:uploaded_files, [])
      |> allow_upload(:picture, accept: ~w(.jpg .jpeg .png), max_entries: 1)
    }
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

  # sobelow_skip ["Traversal"]
  # traversal is not possible due to dest coming from application config
  # TODO move this to a separate module to handle physical file access
  @impl Phoenix.LiveView
  def handle_event("save", _params, socket) do
    consumed_uploads =
      consume_uploaded_entries(socket, :picture, fn %{path: path}, _entry ->
        dest = Application.fetch_env!(:relaxir, RelaxirWeb.UploadLive)[:dest]
        {:ok, filename} = resize(path, dest, "640", "480", "full")

        if socket.assigns.upload_image_filename != "" do
          File.rm(Path.join(dest, "#{socket.assigns.upload_image_filename}-full.jpg"))
        end
        {:ok, filename}
      end)

    # These come from the target's show.html.heex as query paramters
    image_filename =
      hd(consumed_uploads)
      |> String.split("/")
      |> Enum.at(1)
      |> String.trim_trailing("-full.jpg")

    # Callback to target so it can handle updating its own image_filepath
    redirect = "#{socket.assigns.upload_redirect}?image_filename=#{image_filename}"

    {
      :noreply,
      redirect(socket, to: redirect)
    }
  end

  # sobelow_skip ["Traversal"]
  # Traversal is not possible due to dest coming from application config
  # TODO move this to a separate module to handle physical file access
  defp resize(path, dest, width, height, suffix) do
    image_filename = Path.join(dest, "#{Path.basename(path)}-#{suffix}.jpg")

    {_, 0} = System.cmd("gm", [
      "convert",
      path,
      "-resize", "#{width}x#{height}^",
      "-gravity", "Center",
      "-crop", "#{width}x#{height}+0+0",
      "+profile", "'*'",
      "-compress", "JPEG",
      image_filename
    ])

    :ok = File.chmod(image_filename, 0o644)

    {:ok, image_filename}
  end
end
