defmodule Relaxir.Repo.Migrations.ModifyRecipesIngredientsAddPrimaryKey do
  use Ecto.Migration

  def change do
    rename(table(:recipes_ingredients), to: table(:recipe_ingredients))

    alter table(:recipe_ingredients) do
      add(:id, :serial, primary_key: true)
    end
  end
end
