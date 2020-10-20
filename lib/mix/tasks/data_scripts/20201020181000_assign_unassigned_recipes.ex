defmodule Mix.Tasks.Relaxir.AssignUnassignedRecipes do
  use Mix.Task
  import Ecto.Query

  alias Relaxir.Repo
  alias Relaxir.Recipes.Recipe

  @shortdoc "assign all unassigned recipes to user 1"
  def run(_) do
    [:postgrex, :ecto]
    |> Enum.each(&Application.ensure_all_started/1)

    Repo.start_link()
    query = from r in Recipe, where: is_nil(r.user_id)
    Repo.all(query)
    |> Enum.each(fn recipe ->
      recipe
      |> Recipe.changeset(%{user_id: 1})
      |> Repo.update()
    end)
  end
end
