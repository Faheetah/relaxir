defmodule Relaxir.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add(:name, :string)

      timestamps()
    end

    create table(:recipe_categories, primary_key: false) do
      add(:recipe_id, references(:recipes))
      add(:category_id, references(:categories))
    end

    create(unique_index(:categories, [:name]))
    create unique_index(:recipe_categories, [:recipe_id, :category_id])
  end
end
