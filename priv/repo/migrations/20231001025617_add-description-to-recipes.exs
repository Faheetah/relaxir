defmodule :"Elixir.Relaxir.Repo.Migrations.Add-description-to-recipes" do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add(:description, :text)
    end
  end
end
