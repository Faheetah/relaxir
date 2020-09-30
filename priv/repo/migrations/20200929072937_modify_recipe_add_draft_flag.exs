defmodule Relaxir.Repo.Migrations.ModifyRecipeAddDraftFlag do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add :published, :boolean
    end
  end
end
