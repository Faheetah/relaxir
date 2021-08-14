defmodule Relaxir.Users do
  @moduledoc false

  import Ecto.Changeset

  alias Relaxir.Repo
  alias __MODULE__.User

  def register(%Ueberauth.Auth{} = params) do
    %User{}
    |> User.changeset(extract_user_params(params))
    |> Repo.insert()
  end

  def get_or_register(%Ueberauth.Auth{info: %{email: email}} = params) do
    if user = get_by_email(String.downcase(email)) do
      {:ok, user}
    else
      register(params)
    end
  end

  def change_user(user \\ %User{}) do
    User.changeset(user, %{})
  end

  def set_admin(id) do
    change(get_user(id))
    |> put_change(:is_admin, true)
    |> Repo.update()
  end

  defp extract_user_params(%{credentials: %{other: other}, info: info}) do
    info
    |> Map.from_struct()
    |> Map.merge(other)
  end

  def get_user(id) do
    Repo.get(User, id)
  end

  def get_by_email(email) do
    Repo.get_by(User, email: String.downcase(email))
  end

  def reset_password(user, password, password_confirmation) do
    user
    |> User.changeset(%{password: password, password_confirmation: password_confirmation})
    |> Repo.insert()
  end
end
