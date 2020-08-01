defmodule RelaxirWeb.PageController do
  use RelaxirWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
