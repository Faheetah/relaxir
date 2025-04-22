defmodule Relaxir.RecipeCategory do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.Repo
  alias Relaxir.Categories.Category

  @primary_key false

  schema "recipe_categories" do
    belongs_to :recipe, Relaxir.Recipes.Recipe, primary_key: true
    belongs_to :category, Relaxir.Categories.Category, primary_key: true
  end

  def changeset(recipe_category, attrs) do
    recipe_category
    |> cast(attrs, [:recipe_id, :category_id])
    |> cast_assoc(:recipe)
    |> cast_assoc(:category)
  end

  def parse_categories(attrs, insert?) do
    (attrs["categories"] || [])
    |> Enum.map(&String.trim/1)
    |> Enum.reject(& &1 == "")
    |> Enum.map(& get_or_insert_category(&1, insert?))
  end

  def get_or_insert_category(name, false), do: %Category{name: name}
  def get_or_insert_category(name, true) do
    name = String.downcase(name)
    Repo.get_by(Category, name: name) || Repo.insert(%Category{name: name})
  end
end
