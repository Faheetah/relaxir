defmodule Relaxir.Repo.Migrations.CreateInventoryLists do
  use Ecto.Migration

  def change do
    create table(:inventory_lists) do
      add :name, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create table(:ingredient_inventory_lists) do
      add :ingredient_id, references(:ingredients)
      add :inventory_list_id, references(:inventory_lists, on_delete: :delete_all)
    end

    create index(:inventory_lists, [:user_id])
    create unique_index(:inventory_lists, [:name])
  end
end
