defmodule Relaxir.Repo.Migrations.ModifyUnitsAddName do
  use Ecto.Migration

  def change do
    alter table(:units) do
      add :name, :string
    end

    create unique_index(:units, [:name])
  end
end
