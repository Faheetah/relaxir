defmodule Relaxir.Repo.Migrations.CreateRecipes do
  use Ecto.Migration

  def change do
    create table(:recipes) do
      add(:title, :string, null: false)
      add(:directions, :text)
      add(:published, :boolean)
      add(:image_filename, :string)
      add(:note, :text)
      add(:description, :text)
      add(:gluten_free, :boolean, default: false)
      add(:keto, :boolean, default: false)
      add(:vegetarian, :boolean, default: false)
      add(:vegan, :boolean, default: false)
      add(:spicy, :boolean, default: false)
      # add(:user_id, references(:users)) # handled in user_auth_tables

      timestamps()
    end

    alter table(:ingredients) do
      add(:source_recipe_id, references(:recipes))
    end

    create(unique_index(:recipes, [:title]))

  end
end
