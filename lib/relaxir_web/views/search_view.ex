defmodule RelaxirWeb.SearchView do
  use RelaxirWeb, :view

  def route_exists(uri) do
    case Phoenix.Router.route_info(RelaxirWeb.Router, "GET", uri, "") do
      :error -> false
      _ -> true
    end
  end
end
