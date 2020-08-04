defmodule RelaxirWeb.ProfileController do
  use RelaxirWeb, :controller
  alias RelaxirWeb.Authentication

  def show(conn, _parameters) do
    current_user = Authentication.get_current_user(conn)
    render(conn, :show, current_user: current_user)
  end
end
