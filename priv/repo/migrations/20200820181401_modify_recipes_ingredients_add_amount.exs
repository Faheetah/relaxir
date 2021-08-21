defmodule Relaxir.Repo.Migrations.ModifyRecipesIngredientsAddAmount do
  use Ecto.Migration

  def change do
    alter table(:recipe_ingredients) do
      add(:amount, :integer)
    end
  end
end
