defmodule Relaxir.Repo.Migrations.AddNameIndexToRecipes do
  use Ecto.Migration

  def change do
    create unique_index(:recipes, [:title])
  end
end
