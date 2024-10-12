defmodule Relaxir.Repo.Migrations.CreateIngredientUnits do
  use Ecto.Migration

  def change do
    create table(:units) do
      add(:name, :string)
      add(:abbreviation, :string)
    end

    alter table(:recipe_ingredients) do
      add(:unit_id, references(:units))
      add(:note, :string)
    end

    create(unique_index(:units, [:name]))
  end
end
