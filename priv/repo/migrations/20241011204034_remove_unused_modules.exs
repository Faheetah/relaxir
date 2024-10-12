defmodule Relaxir.Repo.Migrations.RemoveUsdaInformation do
  use Ecto.Migration

  def up do
    alter table(:ingredients) do
      remove :food_id
    end

    # Remove USDA

    drop_if_exists unique_index(:foods, [:fdc_id])
    drop_if_exists table(:foods)
    drop_if_exists table(:nutrients)
    drop_if_exists index(:food_nutrients, [:fdc_id, :nutrient_id])
    drop_if_exists table(:food_nutrients)
    drop_if_exists unique_index(:foods, [:description])

    execute "DELETE FROM schema_migrations WHERE version = 20200809203359 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200809203359);"
    execute "DELETE FROM schema_migrations WHERE version = 20200809211033 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200809211033);"
    execute "DELETE FROM schema_migrations WHERE version = 20200809204335 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200809204335);"
    execute "DELETE FROM schema_migrations WHERE version = 20200919094723 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200919094723);"
    execute "DELETE FROM schema_migrations WHERE version = 20211121044342 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20211121044342);"
    execute "DELETE FROM schema_migrations WHERE version = 20201107031528 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20201107031528);"

    # Remove recipe lists

    drop_if_exists index(:recipe_lists, [:name])
    drop_if_exists index(:recipe_lists, [:user_id])
    drop_if_exists table(:recipe_recipe_lists), mode: :cascade
    drop_if_exists table(:recipe_lists), mode: :cascade

    # Remove grocery lists

    drop_if_exists index(:grocery_lists, [:user_id])
    drop_if_exists unique_index(:grocery_lists, [:name])
    drop_if_exists table(:ingredient_grocery_lists)
    drop_if_exists table(:grocery_lists)
    execute "DELETE FROM schema_migrations WHERE version = 20201025151641 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20201025151641);"
    execute "DELETE FROM schema_migrations WHERE version = 20210320063852 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20210320063852);"

    # Remove inventory lists

    drop_if_exists index(:inventory_lists, [:user_id])
    drop_if_exists unique_index(:inventory_lists, [:name])
    drop_if_exists table(:ingredient_inventory_lists)
    drop_if_exists table(:inventory_lists)
    execute "DELETE FROM schema_migrations WHERE version = 20201027033825 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20201027033825);"
    execute "DELETE FROM schema_migrations WHERE version = 20201219205627 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20201219205627);"
  end
end
