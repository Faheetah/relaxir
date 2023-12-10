defmodule Relaxir.Repo.Migrations.AddRecipeSourceToIngredients do
  use Ecto.Migration

  def change do
    alter table(:ingredients) do
      add(:source_recipe_id, references(:recipes))
    end
  end
end
