defmodule Relaxir.Repo.Migrations.RemoveInventoryLists do
  use Ecto.Migration

  def up do
    drop_if_exists index(:inventory_lists, [:user_id])
    drop_if_exists unique_index(:inventory_lists, [:name])
    drop_if_exists table(:ingredient_inventory_lists)
    drop_if_exists table(:inventory_lists)
    execute "DELETE FROM schema_migrations WHERE version = 20201027033825 AND EXISTS (SELECT version FROM schema_migrations WHERE version = 20201027033825);"
  end

  def down do
    # 20201027033825 Relaxir.Repo.Migrations.CreateInventoryLists do
    create table(:inventory_lists) do
      add(:name, :string)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create table(:ingredient_inventory_lists) do
      add(:ingredient_id, references(:ingredients))
      add(:inventory_list_id, references(:inventory_lists, on_delete: :delete_all))
    end

    create(index(:inventory_lists, [:user_id]))
    create(unique_index(:inventory_lists, [:name]))
    execute "INSERT INTO schema_migrations (version) VALUES (20201027033825);"
  end
end
