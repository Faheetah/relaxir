defmodule Relaxir.Repo.Migrations.ModifyInventoryListsAddArbitraryField do
  use Ecto.Migration

  def change do
    alter table(:ingredient_inventory_lists) do
      add(:note, :string)
    end
  end
end
