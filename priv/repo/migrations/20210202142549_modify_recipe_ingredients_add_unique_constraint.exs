defmodule Relaxir.Repo.Migrations.ModifyRecipeIngredientsAddUniqueConstraint do
  use Ecto.Migration

  def change do
    create unique_index(:recipe_ingredients, [:recipe_id, :ingredient_id])
  end
end
