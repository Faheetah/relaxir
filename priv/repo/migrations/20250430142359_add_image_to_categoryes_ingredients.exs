defmodule :"Elixir.Relaxir.Repo.Migrations.Add-image-to-categoryes-ingredients" do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add(:image_filename, :string)
    end

    alter table(:ingredients) do
      add(:image_filename, :string)
    end
  end
end
