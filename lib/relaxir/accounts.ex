defmodule Relaxir.Accounts do
  alias Relaxir.Repo
  alias __MODULE__.Account

  def register(%Ueberauth.Auth{provider: :identity} = params) do
    %Account{}
    |> Account.changeset(extract_account_params(params))
    |> Relaxir.Repo.insert()
  end

  def register(%Ueberauth.Auth{} = params) do
    %Account{}
    |> Account.oauth_changeset(extract_account_params(params))
    |> Relaxir.Repo.insert()
  end

  def get_or_register(%Ueberauth.Auth{info: %{email: email}} = params) do
    if account = get_by_email(email) do
      {:ok, account}
    else
      register(params)
    end
  end

  def change_account(account \\ %Account{}) do
    Account.changeset(account, %{})
  end

  defp extract_account_params(%{credentials: %{other: other}, info: info}) do
    info
    |> Map.from_struct()
    |> Map.merge(other)
  end

  def get_account(id) do
    Repo.get(Account, id)
  end

  def get_by_email(email) do
    Repo.get_by(Account, email: email)
  end
end
