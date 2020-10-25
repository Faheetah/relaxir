defmodule Relaxir.RecipeLists.RecipeList do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recipe_lists" do
    field :name, :string
    belongs_to :user, Relaxir.Users.User
    has_many :recipe_recipe_lists, Relaxir.RecipeRecipeList
    has_many :recipes, through: [:recipe_recipe_lists, :recipe], on_replace: :delete

    timestamps()
  end

  def changeset(recipe_list, attrs) do
    recipe_list
    |> cast(attrs, [:name, :user_id])
    |> cast_assoc(:recipe_recipe_lists)
    |> validate_required([:name, :user_id])
    |> unique_constraint([:name])
  end
end
