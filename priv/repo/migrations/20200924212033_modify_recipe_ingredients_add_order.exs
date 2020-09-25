defmodule Relaxir.Repo.Migrations.ModifyRecipeIngredientsAddOrder do
  use Ecto.Migration

  def change do
    alter table(:recipe_ingredients) do
      add :order, :integer
    end
  end
end
