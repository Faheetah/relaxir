defmodule RelaxirWeb.UploadLive do
  use RelaxirWeb, :live_view

  @impl Phoenix.LiveView
  def mount(%{"path" => upload_image_filename, "redirect" => upload_redirect} = params, _session, socket) do
    preserve_size = Map.get(params, "preserve_size", "false") == "true"

    {
      :ok,
      socket
      |> assign(:upload_image_filename, upload_image_filename)
      |> assign(:upload_redirect, upload_redirect)
      |> assign(:preserve_size, preserve_size)
      |> assign(:uploaded_files, [])
      |> allow_upload(:picture, accept: ~w(.jpg .jpeg .png .avif), max_entries: 1)
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

        filename =
          if socket.assigns.preserve_size do
            {:ok, filename} = Relaxir.Uploader.copy(path, dest, "full")
            filename
          else
            {:ok, filename} = Relaxir.Uploader.resize(path, dest, "640", "480", "full")
            filename
          end

        Relaxir.Uploader.remove_previous(dest, socket.assigns.upload_image_filename)
        {:ok, filename}
      end)

    # These come from the target's show.html.heex as query paramters
    full_filename = hd(consumed_uploads) |> String.split("/") |> Enum.at(-1)

    # Extract base filename by removing "-full" suffix (with optional extension)
    # The file could be "filename-full.jpg", "filename-full.png", or "filename-full" (no extension)
    image_filename =
      case Regex.run(~r/^(.*)-full(?:\.[^.]+)?$/, full_filename) do
        [_, base_name] -> base_name
        _ -> String.trim_trailing(full_filename, "-full.jpg") # fallback for backward compatibility
      end

    # Callback to target so it can handle updating its own image_filepath
    redirect = "#{socket.assigns.upload_redirect}?image_filename=#{image_filename}"

    {
      :noreply,
      redirect(socket, to: redirect)
    }
  end
end
