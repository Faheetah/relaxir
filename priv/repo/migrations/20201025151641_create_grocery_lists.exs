defmodule Relaxir.Repo.Migrations.CreateGroceryLists do
  use Ecto.Migration

  def change do
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
  end
end
