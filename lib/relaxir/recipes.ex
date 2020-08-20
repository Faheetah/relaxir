defmodule Relaxir.Recipes do
  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias Relaxir.Repo

  alias Relaxir.Recipes.Recipe

  def list_recipes do
    Repo.all(Recipe)
  end

  def get_recipe!(id) do
    Recipe
    |> preload([:recipe_ingredients, :ingredients, :categories])
    |> Repo.get!(id)
  end

  def create_recipe!(attrs \\ %{}) do
    {:ok, recipe} = create_recipe(attrs)
    recipe
  end

  def create_recipe(attrs \\ %{}) do
    %Recipe{}
    |> Recipe.changeset(attrs)
    |> put_assoc(:categories, attrs["categories"])
    |> Repo.insert()
  end

  def update_recipe(%Recipe{} = recipe, attrs) do
    recipe
    |> Recipe.changeset(extract_recipe_ingredients(recipe, attrs))
    |> put_assoc(:categories, attrs["categories"])
    |> Repo.update()
  end

  def delete_recipe(%Recipe{} = recipe) do
    Repo.delete(recipe)
  end

  def change_recipe(%Recipe{} = recipe, attrs \\ %{}) do
    Recipe.changeset(recipe, attrs)
  end

  def extract_recipe_ingredients(recipe, attrs) do
    current_recipe_ingredients = recipe.recipe_ingredients
    |> Enum.reduce([],
      fn (ri, acc) ->
        [%{id: ri.id, ingredient: %{id: ri.ingredient.id}} | acc]
      end
    )

    recipe_ingredients = attrs["recipe_ingredients"]
    |> Enum.map(fn i ->
      case i do
        %{:ingredient_id => id} -> Enum.find(
          current_recipe_ingredients,
          %{recipe_id: recipe.id, ingredient_id: id}, 
          fn cri ->
            if cri.ingredient.id == id do 
              cri
            end
          end)
        _ -> i
      end
    end)

    Map.merge(attrs, %{"recipe_ingredients" => recipe_ingredients})
  end
end
