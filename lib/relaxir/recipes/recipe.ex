defmodule Relaxir.Recipes.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.RecipeIngredient
  alias Relaxir.RecipeCategory
  alias Relaxir.Ingredients.Ingredient
  alias Relaxir.Categories.Category

  schema "recipes" do
    field :directions, :string
    field :title, :string
    many_to_many :ingredients, Ingredient, join_through: RecipeIngredient, on_replace: :delete
    many_to_many :categories, Category, join_through: RecipeCategory, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [:title, :directions])
    |> validate_required([:title])
  end
end
