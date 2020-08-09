defmodule Relaxir.Repo.Migrations.CreateNutrients do
  use Ecto.Migration

  def change do
    create table(:nutrients) do
      add :name, :string
      add :unit_name, :string
      add :nutrient_nbr, :string
      add :rank, :integer

      timestamps()
    end

  end
end
