defmodule RelaxirWeb.ToolController do
  use RelaxirWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, %{"name" => "dishers"}) do
    render(conn, "dishers.html")
  end

  def show(conn, %{"name" => "conversions"}) do
    render(conn, "conversions.html")
  end

  def show(conn, _tool) do
    render(conn, "index.html")
  end
end
