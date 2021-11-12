defmodule Relaxir.Search do

  @search_table_mapping %{
    recipes: {Relaxir.Recipes.Recipe, :title},
    categories: {Relaxir.Categories.Category, :name},
    ingredients: {Relaxir.Ingredients.Ingredient, :name},
    usda: {Relaxir.Ingredients.Food, :description}
  }

  @spec search_for([atom], String.t) :: [{term, integer}]
  def search_for(fields, terms) do
    fields
    |> Enum.filter(fn {field, _} -> @search_table_mapping[field] end)
    |> Enum.reduce(%{}, fn {field, _}, acc -> Map.put(acc, field, search_table(@search_table_mapping[field], terms)) end)
  end

  def search_table({module, name}, terms) do
    case Invert.get(module, name, terms) do
      {:ok, results} -> results
      {:error, :not_found} -> []
    end
    |> Enum.sort_by(
      fn {[term, _], score} ->
        score - String.length(term) / 1000
      end,
      :desc
    )
  end
end
