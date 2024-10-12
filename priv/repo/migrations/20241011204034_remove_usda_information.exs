defmodule Relaxir.Repo.Migrations.RemoveUsdaInformation do
  use Ecto.Migration

  def up do
    alter table(:ingredients) do
      remove :food_id
    end

    drop_if_exists unique_index(:foods, [:fdc_id])
    drop_if_exists table(:foods)
    drop_if_exists table(:nutrients)
    drop_if_exists index(:food_nutrients, [:fdc_id, :nutrient_id])
    drop_if_exists table(:food_nutrients)
    drop_if_exists unique_index(:foods, [:description])
  end

  def down do
    # 20200809203359 Relaxir.Repo.Migrations.CreateFoods
    create table(:foods) do
      add(:fdc_id, :integer)
      add(:data_type, :string)
      add(:description, :string)
      add(:food_category_id, :integer)
      add(:publication_date, :date)

      timestamps()
    end
    create(unique_index(:foods, [:fdc_id]))


    # 20200809211033 Relaxir.Repo.Migrations.CreateNutrients
    create table(:nutrients) do
      add(:name, :string)
      add(:unit_name, :string)
      add(:nutrient_nbr, :string)
      add(:rank, :integer)

      timestamps()
    end


    # 20200809204335 Relaxir.Repo.Migrations.CreateFoodNutrients
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


    # 20200919094723 Relaxir.Repo.Migrations.AddDescriptionIndexToIngredientsFood do
    create(unique_index(:foods, [:description]))

    # 20211121044342 Relaxir.Repo.Migrations.AddFoodNutrientsIndex
    create(index(:food_nutrients, [:fdc_id, :nutrient_id]))

    # 20201107031528 Relaxir.Repo.Migrations.ModifyIngredientsAddUsdaColumn
    alter table(:ingredients) do
      add(:food_id, references(:foods))
    end
  end
end
