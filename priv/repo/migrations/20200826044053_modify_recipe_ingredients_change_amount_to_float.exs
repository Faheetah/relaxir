defmodule Relaxir.Repo.Migrations.ModifyRecipeIngredientsChangeAmountToFloat do
  use Ecto.Migration

  def change do
    alter table(:recipe_ingredients) do
      modify :amount, :float
    end
  end
end
