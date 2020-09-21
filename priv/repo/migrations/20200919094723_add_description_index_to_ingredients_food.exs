defmodule Relaxir.Repo.Migrations.AddDescriptionIndexToIngredientsFood do
  use Ecto.Migration

  def change do
    create unique_index(:foods, [:description])
  end
end
