defmodule Relaxir.Repo.Migrations.AddNotesToRecipes do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add(:note, :string)
    end
  end
end
