defmodule Relaxir.Repo.Migrations.CreateRecipes do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      modify :directions, :text
    end

  end
end
