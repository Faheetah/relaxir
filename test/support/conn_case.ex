defmodule RelaxirWeb.ConnCase do
  use ExUnit.CaseTemplate
  import Phoenix.ConnTest

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
 
    if user = Relaxir.Users.get_by_email("test@test") do
      {:ok, user}
    else
      user = %Relaxir.Users.User{}
      |> Relaxir.Users.User.changeset(%{email: "test@test", password: "test", password_confirmation: "test", is_admin: true})
      |> Relaxir.Repo.insert!()
    end

    conn = Phoenix.ConnTest.build_conn()
    |> RelaxirWeb.Authentication.log_in(user)
    {:ok, conn: conn}
  end
end
