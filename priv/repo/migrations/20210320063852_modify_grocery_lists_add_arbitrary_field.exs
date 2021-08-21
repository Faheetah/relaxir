defmodule Relaxir.Repo.Migrations.ModifyGroceryListsAddArbitraryField do
  use Ecto.Migration

  def change do
    alter table(:grocery_lists) do
      add(:note, :text)
    end
  end
end
