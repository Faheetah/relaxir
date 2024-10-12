defmodule Relaxir.Repo.Migrations.SquashMigrations do
  use Ecto.Migration

  def up do
    alter table(:ingredients) do
      remove_if_exists :food_id
    end

    # Remove USDA

    drop_if_exists unique_index(:foods, [:fdc_id])
    drop_if_exists table(:foods)
    drop_if_exists table(:nutrients)
    drop_if_exists index(:food_nutrients, [:fdc_id, :nutrient_id])
    drop_if_exists table(:food_nutrients)
    drop_if_exists unique_index(:foods, [:description])

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

    # Remove inventory lists

    drop_if_exists index(:inventory_lists, [:user_id])
    drop_if_exists unique_index(:inventory_lists, [:name])
    drop_if_exists table(:ingredient_inventory_lists)
    drop_if_exists table(:inventory_lists)

    execute "DELETE FROM schema_migrations WHERE version = 20200809203359 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200809203359);"
    execute "DELETE FROM schema_migrations WHERE version = 20200809211033 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200809211033);"
    execute "DELETE FROM schema_migrations WHERE version = 20200809204335 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200809204335);"
    execute "DELETE FROM schema_migrations WHERE version = 20200919094723 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200919094723);"
    execute "DELETE FROM schema_migrations WHERE version = 20211121044342 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20211121044342);"
    execute "DELETE FROM schema_migrations WHERE version = 20201107031528 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20201107031528);"
    execute "DELETE FROM schema_migrations WHERE version = 20201025151641 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20201025151641);"
    execute "DELETE FROM schema_migrations WHERE version = 20210320063852 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20210320063852);"
    execute "DELETE FROM schema_migrations WHERE version = 20201027033825 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20201027033825);"
    execute "DELETE FROM schema_migrations WHERE version = 20201219205627 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20201219205627);"
    execute "DELETE FROM schema_migrations WHERE version = 20200810170900 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200810170900);"
    execute "DELETE FROM schema_migrations WHERE version = 20200812031722 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200812031722);"
    execute "DELETE FROM schema_migrations WHERE version = 20200815130903 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200815130903);"
    execute "DELETE FROM schema_migrations WHERE version = 20200820181401 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200820181401);"
    execute "DELETE FROM schema_migrations WHERE version = 20200821052245 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200821052245);"
    execute "DELETE FROM schema_migrations WHERE version = 20200826044053 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200826044053);"
    execute "DELETE FROM schema_migrations WHERE version = 20200830151806 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200830151806);"
    execute "DELETE FROM schema_migrations WHERE version = 20200920233718 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200920233718);"
    execute "DELETE FROM schema_migrations WHERE version = 20200922024927 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200922024927);"
    execute "DELETE FROM schema_migrations WHERE version = 20200924212033 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200924212033);"
    execute "DELETE FROM schema_migrations WHERE version = 20200929072937 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200929072937);"
    execute "DELETE FROM schema_migrations WHERE version = 20201019012008 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20201019012008);"
    execute "DELETE FROM schema_migrations WHERE version = 20201019215618 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20201019215618);"
    execute "DELETE FROM schema_migrations WHERE version = 20210202142549 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20210202142549);"
    execute "DELETE FROM schema_migrations WHERE version = 20211123175032 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20211123175032);"
    execute "DELETE FROM schema_migrations WHERE version = 20220212181806 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20220212181806);"
    execute "DELETE FROM schema_migrations WHERE version = 20231001025617 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20231001025617);"
    execute "DELETE FROM schema_migrations WHERE version = 20231003034534 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20231003034534);"
    execute "DELETE FROM schema_migrations WHERE version = 20231007152901 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20231007152901);"
    execute "DELETE FROM schema_migrations WHERE version = 20231007193120 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20231007193120);"
    execute "DELETE FROM schema_migrations WHERE version = 20231210153952 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20231210153952);"
    execute "DELETE FROM schema_migrations WHERE version = 20241011183650 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20241011183650);"
    execute "DELETE FROM schema_migrations WHERE version = 20230919140356 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20230919140356);"
    execute "DELETE FROM schema_migrations WHERE version = 20200803034934 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20200803034934);"
  end
end
