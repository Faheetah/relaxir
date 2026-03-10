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

  @impl Phoenix.LiveView
  def handle_event("save", _params, socket) do
    consumed_uploads =
      consume_uploaded_entries(socket, :picture, fn %{path: path}, _entry ->
        dest = Application.fetch_env!(:relaxir, RelaxirWeb.UploadLive)[:dest]
        {:ok, filename} = Relaxir.Uploader.resize(path, dest, "640", "480", "full")

        Relaxir.Uploader.remove_previous(dest, socket.assigns.upload_image_filename)
        {:ok, filename}
      end)

    # These come from the target's show.html.heex as query paramters
    image_filename =
      hd(consumed_uploads)
      |> String.split("/")
      |> Enum.at(-1)
      |> String.trim_trailing("-full.jpg")

    # Callback to target so it can handle updating its own image_filepath
    redirect = "#{socket.assigns.upload_redirect}?image_filename=#{image_filename}"

    {
      :noreply,
      redirect(socket, to: redirect)
    }
  end
end
