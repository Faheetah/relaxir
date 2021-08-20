defmodule RelaxirWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import RelaxirWeb.ConnCase
      import Relaxir.DataHelpers

      alias RelaxirWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint RelaxirWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Relaxir.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Relaxir.Repo, {:shared, self()})
    end

    user = Relaxir.Accounts.get_user!(1)

    conn =
      Phoenix.ConnTest.build_conn()
      |> __MODULE__.log_in_user(user)

    {:ok, conn: conn}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = Relaxir.AccountsFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = Relaxir.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
