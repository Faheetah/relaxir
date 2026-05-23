defmodule Relaxir.Ingredients do
  import Ecto.Query, warn: false
  alias Relaxir.Repo

  alias Relaxir.Ingredients.Ingredient
  alias Relaxir.Recipes.Recipe
  alias Relaxir.RecipeIngredient

  # these ingredients are too common but insignificant, so we will exclude them
  @excluded_ingredient_names ["salt", "pepper", "oil"]

  def list_ingredients() do
    Ingredient
    |> preload([[parent_ingredient: :parent_ingredient, child_ingredients: :child_ingredients]])
    |> order_by(asc: :name)
    |> Repo.all()
  end

  @doc """
  Returns a map of ingredient_id => [recipes] for the given ingredient IDs.
  Returns up to `limit` random published recipes per ingredient.
  """
  def get_recipes_for_ingredients(ingredient_ids, limit \\ 4) do
    from(
      ri in RecipeIngredient,
      where: ri.ingredient_id in ^ingredient_ids,
      join: r in Recipe,
      on: r.id == ri.recipe_id,
      where: r.published == true,
      select: {ri.ingredient_id, r},
      distinct: [ri.ingredient_id, r.id],
      order_by: fragment("RANDOM()"),
      limit: ^limit
    )
    |> Repo.all()
    |> Enum.group_by(fn {id, _recipe} -> id end, fn {_id, recipe} -> recipe end)
  end

  def list_ingredients_missing_parent() do
    query =
      from i in Ingredient,
        where: is_nil(i.parent_ingredient_id),
        preload: [[parent_ingredient: :parent_ingredient, child_ingredients: :child_ingredients]],
        order_by: [asc: :name]

    Repo.all(query)
  end

  def list_pure_ingredients() do
    query =
      from i in Ingredient,
        where: is_nil(i.parent_ingredient_id),
        where:
          fragment(
            "NOT EXISTS (SELECT 1 FROM recipe_ingredients WHERE ingredient_id = ?)",
            i.id
          ),
        preload: [[parent_ingredient: :parent_ingredient, child_ingredients: :child_ingredients]],
        order_by: [asc: :name]

    Repo.all(query)
  end

  def list_ingredients_missing_singular() do
    query =
      from i in Ingredient,
        where: is_nil(i.singular),
        preload: [[parent_ingredient: :parent_ingredient, child_ingredients: :child_ingredients]],
        order_by: [asc: :name]

    Repo.all(query)
  end

  def top_ingredients(limit \\ 4) do
    recipe_count =
      from ri in RecipeIngredient,
        group_by: ri.ingredient_id,
        select: ri.ingredient_id,
        order_by: [desc: count(ri.recipe_id)],
        limit: ^limit

    query =
      from i in Ingredient,
        where: i.name not in @excluded_ingredient_names,
        join: ri in subquery(recipe_count),
        on: i.id == ri.ingredient_id

    query
    |> preload([[child_ingredients: :child_ingredients]])
    |> Repo.all()
    |> Enum.reverse()
    |> Enum.reduce([], fn ingredient, acc ->
      recipes = get_recipes_for_ingredient(ingredient)

      [{ingredient, recipes} | acc]
    end)
  end

  def get_recipes_for_ingredient(ingredient) do
    children =
      ingredient.child_ingredients
      |> Enum.flat_map(fn i -> [i] ++ i.child_ingredients end)
      |> Enum.map(fn i -> i.id end)

    ingredient_ids = [ingredient.id] ++ children

    top_recipes =
      from ri in RecipeIngredient,
        where: ri.ingredient_id in ^ingredient_ids,
        join: r in Recipe,
        on: r.id == ri.recipe_id,
        where: r.id == ri.recipe_id and r.published == true,
        order_by: [desc: r.inserted_at],
        select: r,
        distinct: r

    top_recipes
    |> Repo.all()
    |> Repo.preload(:user)
    |> Repo.preload(:categories)
  end

  def get_ingredient!(id) do
    preloads = [
      :recipes,
      :source_recipe,
      [
        parent_ingredient: :parent_ingredient,
        child_ingredients: :child_ingredients
      ]
    ]

    Ingredient
    |> preload(^preloads)
    |> Repo.get!(id)
  end

  # We only expecet there to ever be 3 levels of ingredients and not arbitrary levels
  def get_ingredient_by_name!(name) do
    Ingredient
    |> preload(parent_ingredient: :parent_ingredient)
    |> Repo.get_by(name: name)
  end

  # Non-bang version that returns nil instead of raising
  def get_ingredient_by_name(name) do
    Ingredient
    |> preload(parent_ingredient: :parent_ingredient)
    |> Repo.get_by(name: name)
  end

  def get_ingredients_by_name!(names) do
    singular_names = Enum.map(names, &Inflex.singularize/1)

    query =
      from ingredient in Ingredient,
        where: ingredient.name in ^singular_names,
        or_where: ingredient.singular in ^singular_names,
        or_where: ingredient.name in ^names,
        select: ingredient

    Repo.all(query)
  end

  def create_ingredient(attrs) do
    %Ingredient{}
    |> Ingredient.changeset(maybe_singularize_attrs(attrs))
    |> Repo.insert()
  end

  def maybe_singularize_attrs(%{"singular" => ""} = attrs), do: Map.put(attrs, "singular", Inflex.singularize(attrs["name"]))
  def maybe_singularize_attrs(attrs), do: attrs

  def update_image_filename(ingredient, image_filename) do
    update_ingredient(ingredient, %{"image_filename" => image_filename})
  end

  def update_ingredient(%Ingredient{} = ingredient, attrs) do
    ingredient
    |> Ingredient.changeset(attrs)
    |> Repo.update()
  end

  def delete_ingredient(%Ingredient{} = ingredient) do
    Repo.delete(ingredient)
  end

  def change_ingredient(%Ingredient{} = ingredient, attrs \\ %{}) do
    Ingredient.changeset(ingredient, attrs)
  end

  @doc """
  Search for ingredients by name prefix (for live_select autocomplete)
  """
  def search_ingredients(query) when is_binary(query) do
    query =
      from i in Ingredient,
        where: ilike(i.name, ^"#{query}%"),
        order_by: [asc: i.name],
        limit: 20

    Repo.all(query)
    |> Enum.map(& &1.name)
  end

  def search_ingredients(_), do: []

  @doc """
  Search for ingredients by substring (fuzzy match) for suggestion purposes.
  Returns full Ingredient structs so we can use their names.
  """
  def search_ingredients_fuzzy(query) when is_binary(query) and byte_size(query) > 0 do
    query_lower = String.downcase(query)
    query_words = String.split(query_lower, ~r/\s+/)

    # First, try exact case-insensitive match
    exact_match =
      from(
        i in Ingredient,
        where: ilike(i.name, ^query),
        limit: 1
      )
      |> Repo.all()

    # If we have exact match, return it
    if exact_match != [] do
      exact_match
    else
      # Otherwise, do broader substring search
      search_term = "%#{query}%"

      # Get substring matches
      substring_matches =
        from(
          i in Ingredient,
          where: ilike(i.name, ^search_term),
          limit: 20
        )
        |> Repo.all()

      # If we have substring matches, sort them by similarity
      if substring_matches != [] do
        substring_matches
        |> Enum.sort_by(fn ingredient ->
          name = String.downcase(ingredient.name)
          name_words = String.split(name, ~r/\s+/)

          # Calculate similarity score
          score = calculate_similarity_score(query_lower, query_words, name, name_words)
          -score  # Negative for descending sort
        end)
        |> Enum.take(8)
      else
        # If no substring matches, try word-by-word similarity
        # Get all ingredients and find the most similar ones
        all_ingredients =
          from(
            i in Ingredient,
            limit: 100
          )
          |> Repo.all()

        all_ingredients
        |> Enum.sort_by(fn ingredient ->
          name = String.downcase(ingredient.name)
          name_words = String.split(name, ~r/\s+/)

          # Calculate similarity score
          score = calculate_similarity_score(query_lower, query_words, name, name_words)
          -score  # Negative for descending sort
        end)
        |> Enum.take(8)
      end
    end
  end

  def search_ingredients_fuzzy(_), do: []

  defp calculate_similarity_score(query, query_words, name, name_words) do
    # 1. Check for exact word matches with better plural handling
    word_match_score =
      Enum.reduce(query_words, 0, fn query_word, acc ->
        case Enum.find(name_words, fn name_word ->
          # Better stemming for plural handling
          stemmed_query = stem_word(query_word)
          stemmed_name = stem_word(name_word)

          # Check multiple matching possibilities
          stemmed_query == stemmed_name ||
          String.contains?(name_word, query_word) ||
          String.contains?(query_word, name_word) ||
          # Also check if singular matches plural
          singular_matches_plural(query_word, name_word) ||
          singular_matches_plural(name_word, query_word)
        end) do
          nil -> acc
          _ -> acc + 1.0
        end
      end) / max(length(query_words), 1)

    # 2. Jaro distance for overall similarity
    jaro_score = String.jaro_distance(query, name)

    # 3. Check if query is contained in name or vice versa
    containment_score =
      cond do
        String.contains?(name, query) -> 0.5
        String.contains?(query, name) -> 0.3
        true -> 0.0
      end

    # Weighted combination of scores
    (word_match_score * 0.5) + (jaro_score * 0.3) + (containment_score * 0.2)
  end

  defp stem_word(word) do
    # Remove common plural endings to get base form
    # Try different patterns in order of specificity
    cond do
      # Words ending in "ies" -> "y" (cherries -> cherry)
      String.ends_with?(word, "ies") ->
        String.replace_suffix(word, "ies", "y")
      # Words ending in "es" where removing "es" gives valid word
      # Check common patterns: potatoes -> potato, tomatoes -> tomato
      String.ends_with?(word, "oes") ->
        String.replace_suffix(word, "oes", "o")
      String.ends_with?(word, "es") ->
        String.replace_suffix(word, "es", "")
      # Regular plural with "s"
      String.ends_with?(word, "s") ->
        String.replace_suffix(word, "s", "")
      true ->
        word
    end
  end

  defp singular_matches_plural(singular, plural) do
    # Check if singular word matches plural form
    stemmed_plural = stem_word(plural)

    # Direct match after stemming
    singular == stemmed_plural ||
    # Also check if plural is just singular + "s" or + "es"
    plural == singular <> "s" ||
    plural == singular <> "es" ||
    # Handle irregular: potato -> potatoes (actually potato + "es")
    (String.ends_with?(singular, "o") and plural == singular <> "es") ||
    # Handle: tomato -> tomatoes
    (String.ends_with?(singular, "to") and plural == singular <> "es")
  end
end
