defmodule Relaxir.Repo.Migrations.RemoveRecipeLists do
  use Ecto.Migration

  def change do
    drop_if_exists index(:recipe_lists, [:name])
    drop_if_exists index(:recipe_lists, [:user_id])
    drop_if_exists table(:recipe_recipe_lists), mode: :cascade
    drop_if_exists table(:recipe_lists), mode: :cascade
  end
end
