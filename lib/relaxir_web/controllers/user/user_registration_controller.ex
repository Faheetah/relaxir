defmodule RelaxirWeb.UserRegistrationController do
  use RelaxirWeb, :controller

  alias Relaxir.Accounts
  alias Relaxir.Accounts.User
  alias RelaxirWeb.UserAuth

  def registration_disabled(conn) do
    conn
    |> put_flash(:error, "Registration is disabled on this site")
    |> redirect(to: Routes.recipe_path(conn, :index))
  end

  def new(conn, _params) do
    with {:ok, enabled: true} <- Application.fetch_env(:relaxir, :registration) do
      changeset = Accounts.change_user_registration(%User{})
      render(conn, "new.html", changeset: changeset)
    else
      _ -> registration_disabled(conn)
    end
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, enabled: true} <- Application.fetch_env(:relaxir, :registration) do
      case Accounts.register_user(user_params) do
        {:ok, user} ->
          {:ok, _} =
            Accounts.deliver_user_confirmation_instructions(
              user,
              &Routes.user_confirmation_url(conn, :confirm, &1)
            )

          conn
          |> put_flash(:info, "User created successfully.")
          |> UserAuth.log_in_user(user)

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "new.html", changeset: changeset)
      end
    else
      _ -> registration_disabled(conn)
    end
  end
end
