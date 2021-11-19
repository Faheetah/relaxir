defmodule RelaxirWeb.UsdaController do
  use RelaxirWeb, :controller

  alias Relaxir.Usda

  def index(conn, _params) do
    usda = Usda.list_food()
    render(conn, "index.html", usda: usda)
  end

  def show(conn, %{"id" => id}) do
    usda = Usda.get_food!(id)
    render(conn, "show.html", usda: usda)
  end
end
