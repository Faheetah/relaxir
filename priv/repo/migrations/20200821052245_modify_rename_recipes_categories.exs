defmodule Relaxir.Repo.Migrations.ModifyRenameRecipesCategories do
  use Ecto.Migration

  def change do
    rename(table(:recipes_categories), to: table(:recipe_categories))
  end
end
