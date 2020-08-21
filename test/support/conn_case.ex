defmodule RelaxirWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import RelaxirWeb.ConnCase

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

    user = Relaxir.Users.get_by_email("test@test")

    conn =
      Phoenix.ConnTest.build_conn()
      |> RelaxirWeb.Authentication.log_in(user)

    {:ok, conn: conn}
  end
end
