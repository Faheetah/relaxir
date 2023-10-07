defmodule Relaxir.Repo.Migrations.AddParentIngredientToIngredients do
  use Ecto.Migration

  def change do
    alter table(:ingredients) do
      add(:parent_ingredient_id, references(:ingredients))
    end
  end
end
