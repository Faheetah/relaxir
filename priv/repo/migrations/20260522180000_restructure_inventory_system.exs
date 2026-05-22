defmodule Relaxir.Repo.Migrations.RestructureInventorySystem do
  use Ecto.Migration

  def up do
    # Step 1: Create new inventories table for labels (with temporary name)
    create table(:inventories_new) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :inserted_at, :utc_datetime, null: false, default: fragment("NOW()")
      add :updated_at, :utc_datetime, null: false, default: fragment("NOW()")
    end

    create index(:inventories_new, [:user_id])
    create unique_index(:inventories_new, [:user_id, :name], name: :inventories_user_name_unique)

    # Step 2: Rename existing inventories table to items
    rename table(:inventories), to: table(:items)

    # Step 3: Add new columns to items table
    alter table(:items) do
      # Add name field (defaults to ingredient name)
      add :name, :string
      # Add inventory_id for labeling (will reference new inventories table)
      add :inventory_id, references(:inventories_new, on_delete: :restrict)
    end

    # Step 4: Rename the unique constraint on items
    drop_if_exists constraint(:items, :inventories_user_ingredient_unique)
    create unique_index(:items, [:user_id, :ingredient_id], name: :items_user_ingredient_unique)

    # Step 5: Create index for inventory_id on items
    create index(:items, [:inventory_id])

    # Step 6: Rename inventories_new to inventories
    rename table(:inventories_new), to: table(:inventories)
  end

  def down do
    # Reverse the changes
    # Remove inventory_id foreign key and column
    alter table(:items) do
      remove :inventory_id
      remove :name
    end

    # Rename items back to inventories
    rename table(:items), to: table(:inventories)

    # Drop the new inventories table
    drop table(:inventories)

    # Recreate the original unique constraint
    drop_if_exists constraint(:inventories, :items_user_ingredient_unique)

    create unique_index(:inventories, [:user_id, :ingredient_id],
             name: :inventories_user_ingredient_unique
           )
  end
end
