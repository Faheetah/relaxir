defmodule Relaxir.Repo.Migrations.ModifyRecipesText do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      modify(:directions, :text)
    end
  end
end
