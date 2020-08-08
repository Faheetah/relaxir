defmodule Relaxir.Repo.Migrations.CreateRecipesIngredients do
  use Ecto.Migration

  def change do
    create table(:recipes_ingredients, primary_key: false) do
      add :recipe_id, references(:recipes)
      add :ingredient_id, references(:ingredients)
    end
  end
end
