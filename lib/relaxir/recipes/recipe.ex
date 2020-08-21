defmodule Relaxir.Recipes.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.RecipeIngredient
  alias Relaxir.RecipeCategory

  schema "recipes" do
    field :directions, :string
    field :title, :string
    has_many :recipe_ingredients, RecipeIngredient, on_replace: :delete
    has_many :ingredients, through: [:recipe_ingredients, :ingredient]
    has_many :recipe_categories, RecipeCategory, on_replace: :delete
    has_many :categories, through: [:recipe_categories, :category]

    timestamps()
  end

  def changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [:title, :directions])
    |> cast_assoc(:recipe_categories)
    |> cast_assoc(:recipe_ingredients)
    |> validate_required([:title])
    |> unique_constraint([:title])
  end
end
