defmodule Relaxir.Repo.Migrations.AddIconToInventories do
  use Ecto.Migration

  def change do
    alter table(:inventories) do
      add :icon, :string, default: "shelf"
    end
  end
end
