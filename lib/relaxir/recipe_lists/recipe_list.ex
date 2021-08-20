defmodule Relaxir.RecipeLists.RecipeList do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recipe_lists" do
    field :name, :string
    belongs_to :user, Relaxir.Accounts.User
    has_many :recipe_recipe_lists, Relaxir.RecipeRecipeList, on_replace: :delete, on_delete: :delete_all
    has_many :recipes, through: [:recipe_recipe_lists, :recipe]

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
