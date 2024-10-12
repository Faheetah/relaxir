defmodule Relaxir.Repo.Migrations.CreateRecipes do
  use Ecto.Migration

  def change do
    create table(:recipes) do
      add(:title, :string, null: false)
      add(:directions, :text)
      add(:published, :boolean)
      add(:user_id, references(:users))
      add(:image_filename, :string)
      add(:note, :text)
      add(:description, :text)
      add(:gluten_free, :boolean, default: false)
      add(:keto, :boolean, default: false)
      add(:vegetarian, :boolean, default: false)
      add(:vegan, :boolean, default: false)
      add(:spicy, :boolean, default: false)

      timestamps()
    end

    create(unique_index(:recipes, [:title]))

  end
end
