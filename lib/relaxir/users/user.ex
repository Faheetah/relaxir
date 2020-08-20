defmodule Relaxir.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :encrypted_password, :string
    field :is_admin, :boolean

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :is_admin])
    |> validate_required([:email, :password])
    |> validate_confirmation(:password, required: true)
    |> unique_constraint(:email)
    |> put_encrypted_password()
  end

  defp put_encrypted_password(%{valid?: true, changes: %{password: pw}} = changeset) do
    put_change(changeset, :encrypted_password, Argon2.hash_pwd_salt(pw))
  end

  defp put_encrypted_password(changeset) do
    changeset
  end
end
