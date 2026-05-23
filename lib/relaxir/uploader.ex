defmodule Relaxir.Uploader do
  @moduledoc """
  Handles file upload operations including resizing and storage.
  """

  # sobelow_skip ["Traversal"]
  # Traversal is not possible due to dest coming from application config
  def resize(path, dest, width, height, suffix) do
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

  # sobelow_skip ["Traversal"]
  # Traversal is not possible due to dest coming from application config
  def copy(path, dest, suffix) do
    # Get the original file extension
    ext = Path.extname(path)
    # Ensure we have an extension (default to .jpg for images)
    ext = if ext == "", do: ".jpg", else: ext
    # Create filename with extension
    image_filename = Path.join(dest, "#{Path.basename(path, ext)}-#{suffix}#{ext}")

    # Simply copy the file without any conversion
    File.copy!(path, image_filename)

    :ok = File.chmod(image_filename, 0o644)

    {:ok, image_filename}
  end

  # sobelow_skip ["Traversal"]
  # Traversal is not possible due to dest coming from application config
  def remove_previous(dest, filename) when is_binary(filename) and filename != "" do
    File.rm(Path.join(dest, "#{filename}-full.jpg"))
  end

  def remove_previous(_dest, _filename), do: :ok

  # sobelow_skip ["Traversal"]
  # Traversal is not possible due to dest coming from application config
  def remove_orphaned(dest, file) do
    file_path = Path.join(dest, file)
    case File.rm(file_path) do
      :ok ->
        IO.puts("Deleted file #{file}")
        :ok
      {:error, reason} ->
        IO.puts("Failed to delete #{file}: #{reason}")
        {:error, reason}
    end
  end
end
