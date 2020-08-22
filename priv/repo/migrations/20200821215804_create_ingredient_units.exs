defmodule Relaxir.Repo.Migrations.CreateIngredientUnits do
  use Ecto.Migration

  def change do
    create table(:units) do
      add :singular, :string
      add :plural, :string
    end

    create unique_index(:units, [:singular, :plural])
  end
end
