defmodule Relaxir.Categories.Parser do
  alias Relaxir.Categories

  def downcase_categories(attrs) do
    categories = Map.get(attrs, "categories", [])
    |> Enum.map(&(String.downcase(&1)))
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
    current_recipe_categories =
      recipe.recipe_categories
      |> Enum.reduce(
        [],
        fn ri, acc ->
          [%{id: ri.id, category: %{id: ri.category.id}} | acc]
        end
      )

    recipe_categories =
      (attrs["recipe_categories"] || [])
      |> Enum.map(&(map_existing_category(&1, current_recipe_categories, recipe)))

    Map.put(attrs, "recipe_categories", recipe_categories)
  end

  defp map_existing_category(%{:category_id => id}, categories, recipe) do
    Enum.find(
      categories,
      %{recipe_id: recipe.id, category_id: id},
      fn crc ->
        if crc.category.id == id do
          crc
        end
      end
    )
  end

  defp map_existing_category(category, _categories, _recipe), do: category
end
