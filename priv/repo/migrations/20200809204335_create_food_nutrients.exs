defmodule Relaxir.Repo.Migrations.CreateFoodNutrients do
  use Ecto.Migration

  def change do
    create table(:food_nutrients) do
      add(:fdc_id, :integer)
      add(:nutrient_id, :integer)
      add(:amount, :string)
      add(:data_points, :integer)
      add(:derivation_id, :integer)
      add(:min, :float)
      add(:max, :float)
      add(:median, :float)
      add(:footnote, :string)
      add(:min_year_acquired, :integer)

      timestamps()
    end
  end
end
