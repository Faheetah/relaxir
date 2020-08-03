defmodule RelaxirWeb.ProfileController do
  use RelaxirWeb, :controller
  alias RelaxirWeb.Authentication

  def show(conn, _parameters) do
    current_account = Authentication.get_current_account(conn)
    render(conn, :show, current_account: current_account)
  end
end
