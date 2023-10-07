defmodule Relaxir.Repo.Migrations.AddSingularToIngredients do
  use Ecto.Migration

  def change do
    alter table(:ingredients) do
      add(:singular, :string)
    end
  end
end
