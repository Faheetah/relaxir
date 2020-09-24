defmodule Relaxir.Categories.Parser do
  alias Relaxir.Categories

  def map_categories(attrs) when is_map_key(attrs, "categories") do
    fetched_categories = Categories.get_categories_by_name!(attrs["categories"])

    categories =
      attrs["categories"]
      |> Enum.map(fn name ->
        case Enum.find(fetched_categories, fn c -> c.name == name end) do
          nil -> %{category: %{name: name}}
          category -> %{category_id: category.id}
        end
      end)

    Map.put(attrs, "recipe_categories", categories)
  end

  def map_categories(attrs), do: attrs

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
      |> Enum.map(fn i ->
        case i do
          %{:category_id => id} ->
            Enum.find(
              current_recipe_categories,
              %{recipe_id: recipe.id, category_id: id},
              fn cri ->
                if cri.category.id == id do
                  cri
                end
              end
            )

          _ ->
            i
        end
      end)

    Map.put(attrs, "recipe_categories", recipe_categories)
  end
end
