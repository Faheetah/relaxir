defmodule Relaxir.Repo.Migrations.ModifyUnitsAddAbbreviationColumn do
  use Ecto.Migration

  def change do
    alter table(:units) do
      add(:abbreviation, :string)
    end
  end
end
