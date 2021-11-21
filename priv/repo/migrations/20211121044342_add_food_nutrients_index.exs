defmodule Relaxir.Repo.Migrations.AddFoodNutrientsIndex do
  use Ecto.Migration

  def change do
    create(index(:food_nutrients, [:fdc_id, :nutrient_id]))
  end
end
