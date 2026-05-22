defmodule Relaxir.Repo.Migrations.AddOnDeleteSetNullToItemsInventory do
  use Ecto.Migration

  def up do
    drop constraint("items", "items_inventory_id_fkey")

    alter table("items") do
      modify :inventory_id, references(:inventories, on_delete: :nilify_all)
    end
  end

  def down do
    drop constraint("items", "items_inventory_id_fkey")

    alter table("items") do
      modify :inventory_id, references(:inventories)
    end
  end
end
