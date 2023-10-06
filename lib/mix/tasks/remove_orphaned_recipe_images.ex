defmodule Mix.Tasks.Relaxir.RemoveOrphanedRecipeImages do
  use Mix.Task

  alias Relaxir.Repo
  alias Relaxir.Recipes.Recipe

  def run(_params) do
    [:postgrex, :ecto]
    |> Enum.each(&Application.ensure_all_started/1)

    Repo.start_link()

    file_base_path = Application.fetch_env!(:relaxir, RelaxirWeb.UploadLive)[:dest]
    File.ls(file_base_path)
    |> then(fn {:ok, files} -> files end)
    |> Enum.map(&check_image_exists/1)
  end

  defp check_image_exists(file) do
    image_filename = String.trim_trailing(file, "-full.jpg")
    recipe = Repo.get_by(Recipe, image_filename: image_filename)

    if recipe do
      IO.puts("#{file} belongs to #{recipe.title}")
    else
      Application.fetch_env!(:relaxir, RelaxirWeb.UploadLive)[:dest]
      |> Path.join(file)
      |> File.rm()

      IO.puts("Deleted file #{file}")
    end
  end
end
