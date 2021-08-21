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
    case Application.fetch_env(:relaxir, :registration) do
      {:ok, enabled: true} ->
        changeset = Accounts.change_user_registration(%User{})
        render(conn, "new.html", changeset: changeset)

      _ ->
        registration_disabled(conn)
    end
  end

  def create(conn, %{"user" => user_params}) do
    case Application.fetch_env(:relaxir, :registration) do
      {:ok, enabled: true} ->
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

      _ ->
        registration_disabled(conn)
    end
  end
end
