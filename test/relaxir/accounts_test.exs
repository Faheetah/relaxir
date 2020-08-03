defmodule Relaxir.AccountsTest do
  use Relaxir.DataCase

  alias Relaxir.Accounts
  alias Relaxir.Accounts.Account

  test "register for an account with valid information" do
    pre_count = count_of(Account)
    params = valid_account_params()

    result = Accounts.register(params)

    assert {:ok, %Account{}} = result
    assert pre_count + 1 == count_of(Account)
  end

  test "register for an account with an existing email address" do
    params = valid_account_params()
    Repo.insert!(%Account{email: params.info.email})

    pre_count = count_of(Account)

    result = Accounts.register(params)

    assert {:error, %Ecto.Changeset{}} = result
    assert pre_count == count_of(Account)
  end

  test "register for an account without matching password and confirmation" do
    pre_count = count_of(Account)
    %{credentials: credentials} = params = valid_account_params()

    params = %{
      params
      | credentials: %{
          credentials
          | other: %{
              password: "superdupersecret",
              password_confirmation: "somethingelse"
            }
        }
    }

    result = Accounts.register(params)

    assert {:error, %Ecto.Changeset{}} = result
    assert pre_count == count_of(Account)
  end

  defp count_of(queryable) do
    Relaxir.Repo.aggregate(queryable, :count, :id)
  end

  defp valid_account_params do
    %Ueberauth.Auth{
      credentials: %Ueberauth.Auth.Credentials{
        other: %{
          password: "superdupersecret",
          password_confirmation: "superdupersecret"
        }
      },
      info: %Ueberauth.Auth.Info{
        email: "me@example.com"
      }
    }
  end
end
