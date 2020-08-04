defmodule Relaxir.UsersTest do
  use Relaxir.DataCase

  alias Relaxir.Users
  alias Relaxir.Users.User

  test "register for an user with valid information" do
    pre_count = count_of(User)
    params = valid_user_params()

    result = Users.register(params)

    assert {:ok, %User{}} = result
    assert pre_count + 1 == count_of(User)
  end

  test "register for an user with an existing email address" do
    params = valid_user_params()
    Repo.insert!(%User{email: params.info.email})

    pre_count = count_of(User)

    result = Users.register(params)

    assert {:error, %Ecto.Changeset{}} = result
    assert pre_count == count_of(User)
  end

  test "register for an user without matching password and confirmation" do
    pre_count = count_of(User)
    %{credentials: credentials} = params = valid_user_params()

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

    result = Users.register(params)

    assert {:error, %Ecto.Changeset{}} = result
    assert pre_count == count_of(User)
  end

  defp count_of(queryable) do
    Relaxir.Repo.aggregate(queryable, :count, :id)
  end

  defp valid_user_params do
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
