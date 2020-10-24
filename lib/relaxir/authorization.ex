defmodule Relaxir.Authorization do
  import Ecto.Query

  # this can be expanded later to check if user is admin, hard code for now
  def by_user(query, 1), do: query

  def by_user(query, user_id) do
    where(query, [q], q.user_id == ^user_id)
  end

  # this can be expanded later to check if user is admin, hard code for now
  def preload_by_user(query, association, 1) do
    table =
      association.__schema__(:source)
      |> String.to_existing_atom()

    preload(query, ^table)
  end

  def preload_by_user(query, association, user_id) do
    table =
      association.__schema__(:source)
      |> String.to_existing_atom()

    q = from a in association, where: a.user_id == ^user_id

    preload(query, [{^table, ^q}])
  end
end
