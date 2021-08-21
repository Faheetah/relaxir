defmodule Relaxir.Repo.Migrations.ModifyIngredientsAddUsdaColumn do
  use Ecto.Migration

  def change do
    alter table(:ingredients) do
      add(:food_id, references(:foods))
    end
  end
end
