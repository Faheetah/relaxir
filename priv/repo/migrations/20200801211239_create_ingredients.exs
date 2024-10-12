defmodule Relaxir.Repo.Migrations.CreateIngredients do
  use Ecto.Migration

  def change do
    create table(:ingredients) do
      add(:name, :string)
      add(:description, :text)
      add(:parent_ingredient_id, references(:ingredients))
      add(:singular, :string)
      add(:source_recipe_id, references(:recipes))

      timestamps()
    end

    create(unique_index(:ingredients, [:name]))
  end
end
