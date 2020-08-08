defmodule Relaxir.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string

      timestamps()
    end

    create table(:recipes_categories, primary_keys: false) do
      add :recipe_id, references(:recipes)
      add :category_id, references(:categories)
    end

    create unique_index(:categories, [:name])
  end
end
