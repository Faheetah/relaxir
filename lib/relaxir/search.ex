defmodule Relaxir.Search do
  import Ecto.Query

  alias Relaxir.Repo

  @search_table_mapping %{
    "recipes" => {Relaxir.Recipes.Recipe, :title},
    "categories" => {Relaxir.Categories.Category, :name},
    "ingredients" => {Relaxir.Ingredients.Ingredient, :name}
  }

  @spec search_for([atom] | nil, String.t) :: [{term, integer}]
  def search_for(terms, fields) do
    fields || Map.keys(@search_table_mapping)
    |> Enum.filter(fn field -> @search_table_mapping[field] end)
    |> Enum.reduce(%{}, fn field, acc -> Map.put(acc, field, search_db(@search_table_mapping[field], terms)) end)
  end

  # returns:
  # [
  #   {[result, id], rank]}
  # ]
  def search_db({module, column}, terms) do
    IO.inspect terms
    Repo.all(from m in module, where: ilike(field(m, ^column), ^terms))
    |> Enum.map(fn q -> {[Map.get(q, column), q.id], 1} end)
  end
end
