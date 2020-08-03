defmodule RelaxirWeb.SessionController do
  use RelaxirWeb, :controller

  def new(conn, _params) do
    render(conn, :new, changeset: conn, action: "/login")
  end
end
