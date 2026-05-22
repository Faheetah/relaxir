defmodule Relaxir.Repo.Migrations.UpdateInventoryUniqueConstraint do
  use Ecto.Migration

  def up do
    # Drop the old unique index (ingredient_id + user_id)
    drop_if_exists index(:inventories, [:user_id, :ingredient_id],
                     name: :inventories_user_ingredient_unique
                   )

    # Create a new unique index that includes type
    # Using COALESCE to handle NULL values (treat NULL as empty string for uniqueness)
    execute """
      CREATE UNIQUE INDEX inventories_user_ingredient_type_unique
      ON inventories (user_id, ingredient_id, COALESCE(type, ''))
    """
  end

  def down do
    # Drop the new index
    execute "DROP INDEX IF EXISTS inventories_user_ingredient_type_unique"

    # Recreate the old index
    create unique_index(:inventories, [:user_id, :ingredient_id],
             name: :inventories_user_ingredient_unique
           )
  end
end
