defmodule Relaxir.Repo.Migrations.AddRestockToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :restock, :boolean, default: false, null: false
    end

    create index(:items, [:restock])
  end
end
