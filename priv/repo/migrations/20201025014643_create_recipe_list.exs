defmodule Relaxir.Repo.Migrations.CreateRecipeLists do
  use Ecto.Migration

  def change do
    create table(:recipe_lists) do
      add(:name, :string)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create table(:recipe_recipe_lists) do
      add(:recipe_id, references(:recipes))
      add(:recipe_list_id, references(:recipe_lists, on_delete: :delete_all))
    end

    create(index(:recipe_lists, [:user_id]))
    create(unique_index(:recipe_lists, [:name]))
  end
end
