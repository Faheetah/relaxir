defmodule Relaxir.Categories.Category do
  use Ecto.Schema
  import Ecto.Changeset

  alias Relaxir.RecipeCategory

  @derive {Jason.Encoder, only: [:id, :name]}

  schema "categories" do
    field :name, :string
    has_many :recipe_categories, RecipeCategory
    has_many :recipes, through: [:recipe_categories, :recipe], on_replace: :delete

    timestamps()
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name])
    |> cast_assoc(:recipe_categories)
    |> validate_required([:name])
    |> unique_constraint([:name])
  end
end
