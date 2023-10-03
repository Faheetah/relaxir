defmodule Relaxir.Repo.Migrations.AddRecipeLabels do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add(:gluten_free, :boolean, default: false)
      add(:keto, :boolean, default: false)
      add(:vegetarian, :boolean, default: false)
      add(:vegan, :boolean, default: false)
      add(:spicy, :boolean, default: false)
    end
  end
end
