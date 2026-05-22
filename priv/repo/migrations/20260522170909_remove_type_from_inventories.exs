defmodule Relaxir.Repo.Migrations.RemoveTypeFromInventories do
  use Ecto.Migration

  def up do
    # Drop the unique index that includes type
    execute "DROP INDEX IF EXISTS inventories_user_ingredient_type_unique"

    # Drop the type column
    alter table(:inventories) do
      remove :type
    end

    # Create a new unique index without type
    create unique_index(:inventories, [:user_id, :ingredient_id],
             name: :inventories_user_ingredient_unique
           )
  end

  def down do
    # Drop the new unique index
    drop_if_exists unique_index(:inventories, [:user_id, :ingredient_id],
                     name: :inventories_user_ingredient_unique
                   )

    # Add back the type column
    alter table(:inventories) do
      add :type, :string
    end

    # Recreate the original index with type
    execute """
      CREATE UNIQUE INDEX inventories_user_ingredient_type_unique
      ON inventories (user_id, ingredient_id, COALESCE(type, ''))
    """
  end
end
