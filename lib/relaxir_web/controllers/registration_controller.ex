defmodule RelaxirWeb.RegistrationController do
  use RelaxirWeb, :controller

  def new(conn, _) do
    render(conn, :new, changeset: conn, action: "/register")
  end
end
