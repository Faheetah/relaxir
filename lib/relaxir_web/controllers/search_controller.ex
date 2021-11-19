defmodule RelaxirWeb.SearchController do
  use RelaxirWeb, :controller

  alias Relaxir.Search

  @default_checkboxes %{
    recipes: true,
    categories: true,
    ingredients: true,
    usda: false
  }

  # default search page
  def new(conn, params) when map_size(params) == 0 do
    current_user = conn.assigns.current_user
    render(conn, "search.html", current_user: current_user, count: :na, checkboxes: @default_checkboxes, results: [])
  end

  # search results
  def search(conn, params) do
    terms = params["terms"]
    current_user = conn.assigns.current_user

    checkboxes = %{
      recipes: params["recipes"] || "true",
      categories: params["categories"] || "true",
      ingredients: params["ingredients"] || "true",
      usda: params["usda"] || "true"
    }

    fields =
      params
      |> Enum.filter(fn {_, val} -> val == "true" end)
      |> Enum.map(fn {key, _} -> key end)

    results = Search.search_for(fields, terms)

    count = Enum.reduce(results, 0, fn {_, i}, acc -> acc + length(i) end)

    terms_for = Map.get(params, "for")
    list_id = Map.get(params, "id")

    render(conn, "search.html",
      current_user: current_user,
      count: count,
      checkboxes: checkboxes,
      for: terms_for,
      list_id: list_id,
      results: results
    )
  end
end
