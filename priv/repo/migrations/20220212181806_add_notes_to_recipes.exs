defmodule Relaxir.Repo.Migrations.AddNotesToRecipes do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add(:note, :text)
    end
  end
end
