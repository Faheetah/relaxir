defmodule Relaxir.Repo.Migrations.CreateRecipesIngredients do
  use Ecto.Migration

  def change do
    create table(:recipe_ingredients) do
      add(:recipe_id, references(:recipes))
      add(:ingredient_id, references(:ingredients))
      add(:amount, :float)
      add(:order, :integer)
    end

    create(unique_index(:recipe_ingredients, [:recipe_id, :ingredient_id]))
  end
end
