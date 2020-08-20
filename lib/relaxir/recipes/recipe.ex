defmodule Relaxir.Recipes.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.RecipeIngredient
  alias Relaxir.RecipeCategory
  alias Relaxir.Categories.Category

  schema "recipes" do
    field :directions, :string
    field :title, :string
    has_many :recipe_ingredients, RecipeIngredient, on_replace: :delete
    has_many :ingredients, through: [:recipe_ingredients, :ingredient]
    many_to_many :categories, Category, join_through: RecipeCategory, on_replace: :delete

    timestamps()
  end

  def changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [:title, :directions])
    |> cast_assoc(:recipe_ingredients)
    |> validate_required([:title])
  end
end
