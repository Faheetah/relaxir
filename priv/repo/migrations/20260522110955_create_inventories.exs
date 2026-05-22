defmodule Relaxir.Repo.Migrations.CreateInventories do
  use Ecto.Migration

  def change do
    create table(:inventories) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :ingredient_id, references(:ingredients, on_delete: :delete_all), null: false
      add :unit_id, references(:units, on_delete: :restrict)
      add :amount, :integer, default: 0, null: false
      add :note, :string
      add :type, :string
      add :inserted_at, :utc_datetime, null: false, default: fragment("NOW()")
      add :updated_at, :utc_datetime, null: false, default: fragment("NOW()")
    end

    create index(:inventories, [:user_id])
    create index(:inventories, [:ingredient_id])
    create index(:inventories, [:unit_id])

    # Ensure a user can only have one inventory entry per ingredient
    create unique_index(:inventories, [:user_id, :ingredient_id],
             name: :inventories_user_ingredient_unique
           )
  end
end
