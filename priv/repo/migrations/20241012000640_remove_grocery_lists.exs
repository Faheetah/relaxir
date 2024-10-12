defmodule Relaxir.Repo.Migrations.RemoveGroceryLists do
  use Ecto.Migration

  def up do
    drop_if_exists index(:grocery_lists, [:user_id])
    drop_if_exists unique_index(:grocery_lists, [:name])
    drop_if_exists table(:ingredient_grocery_lists)
    drop_if_exists table(:grocery_lists)
    execute "DELETE FROM schema_migrations WHERE version = 20201025151641 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20201025151641);"
    execute "DELETE FROM schema_migrations WHERE version = 20210320063852 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20210320063852);"
  end

  def down do
    # 20201025151641 Relaxir.Repo.Migrations.CreateGroceryLists do
    create table(:grocery_lists) do
      add(:name, :string)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create table(:ingredient_grocery_lists) do
      add(:ingredient_id, references(:ingredients))
      add(:grocery_list_id, references(:grocery_lists, on_delete: :delete_all))
    end

    create(index(:grocery_lists, [:user_id]))
    create(unique_index(:grocery_lists, [:name]))

    execute "INSERT INTO schema_migrations (version) VALUES (20201025151641);"
  end
end
