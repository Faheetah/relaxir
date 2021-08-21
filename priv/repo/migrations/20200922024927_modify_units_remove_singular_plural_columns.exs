defmodule Relaxir.Repo.Migrations.ModifyUnitsRemoveSingularPluralColumns do
  use Ecto.Migration

  def change do
    alter table(:units) do
      remove(:singular, :string)
      remove(:plural, :string)
    end
  end
end
