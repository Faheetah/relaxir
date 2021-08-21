defmodule Relaxir.Repo.Migrations.ModifyIngredientsAddDescription do
  use Ecto.Migration

  def change do
    alter table(:ingredients) do
      add(:description, :text)
    end
  end
end
