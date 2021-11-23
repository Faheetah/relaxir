defmodule Relaxir.Repo.Migrations.AddImagesToRecipes do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add(:image_filename, :string)
    end
  end
end
