defmodule Relaxir.Repo.Migrations.CreateFoods do
  use Ecto.Migration

  def change do
    create table(:foods) do
      add :fdc_id, :integer
      add :data_type, :string
      add :description, :string
      add :food_category_id, :integer
      add :publication_date, :date

      timestamps()
    end

    create unique_index(:foods, [:fdc_id])
  end
end
