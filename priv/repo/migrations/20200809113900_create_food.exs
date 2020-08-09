defmodule Relaxir.Repo.Migrations.CreateIngredientsFood do
  use Ecto.Migration

  def change do
    create table(:food, primary_keys: :fdc_id) do
      add :fdc_id, :id
      add :data_type, :string
      add :description, :string
      add :food_category_id, :id
      add :publication_date, :string

      timestamps()
    end

    create unique_index(:food, [:fdc_id])
  end
end
