defmodule Relaxir.Repo.Migrations.AddIndexToRecipesCategories do
  use Ecto.Migration

  def change do
    create unique_index(:recipe_categories, [:recipe_id, :category_id])
  end
end
