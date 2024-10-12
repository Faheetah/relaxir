defmodule Relaxir.Categories.Parser do
  alias Relaxir.Categories

  def downcase_categories(attrs) do
    categories =
      Map.get(attrs, "categories", [])
      |> Enum.map(&String.downcase(&1))

    case categories do
      [] -> attrs
      _ -> Map.put(attrs, "categories", categories)
    end
  end

  def map_categories(attrs) when is_map_key(attrs, "categories") do
    fetched_categories = Categories.get_categories_by_name!(attrs["categories"])

    categories =
      attrs["categories"]
      |> Enum.map(fn name ->
        Enum.find(fetched_categories, fn c -> c.name == name end)
        |> map_category(name)
      end)

    Map.put(attrs, "recipe_categories", categories)
  end

  def map_categories(attrs), do: attrs

  defp map_category(nil, name), do: %{category: %{name: name}}
  defp map_category(category, _name), do: %{category_id: category.id}

  def map_existing_categories(attrs, recipe) do
    recipe_categories =
      (attrs["recipe_categories"] || [])
      |> Enum.map(fn rc -> Map.put(rc, :recipe_id, recipe.id) end)

    Map.put(attrs, "recipe_categories", recipe_categories)
  end
end
