defmodule Relaxir.Repo.Migrations.CreateRecipes do
  use Ecto.Migration

  def change do
    create table(:recipes) do
      add :title, :string, null: false
      add :directions, :string

      timestamps()
    end
  end
end
