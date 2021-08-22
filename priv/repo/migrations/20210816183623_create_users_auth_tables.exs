defmodule Relaxir.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS citext", "")

    rename(table(:users), :encrypted_password, to: :hashed_password)

    alter table(:users) do
      modify(:email, :citext, null: false)
      modify(:hashed_password, :string, null: false)
      add(:username, :string)
      add(:confirmed_at, :naive_datetime)
    end

    create table(:users_tokens) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:token, :binary, null: false)
      add(:context, :string, null: false)
      add(:sent_to, :string)
      timestamps(updated_at: false)
    end

    create(index(:users_tokens, [:user_id]))
    create(unique_index(:users_tokens, [:context, :token]))
    create(unique_index(:users, [:username]))
  end
end
