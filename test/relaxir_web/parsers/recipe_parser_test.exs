defmodule RelaxirWeb.RecipeParserTest do
  use ExUnit.Case, async: true
  import RelaxirWeb.RecipeParser

  describe "parsing ingredients" do
    test "returns an ingredients when nothing else is provided" do
      assert {:ok, %{name: "broccoli"}} == extract_ingredient_fields("broccoli")
    end

    test "extracts an amount when a number and two words are provided" do
      assert {:ok, %{name: "broccoli", amount: 1, unit: "cup"}} == extract_ingredient_fields("1 cup broccoli")
    end

    test "parses plural measurements" do
      assert {:ok, %{name: "broccoli", amount: 2, unit: "cups"}} == extract_ingredient_fields("2 cups broccoli")
    end

    test "converts fractional ingredients" do
      assert {:ok, %{name: "broccoli", amount: 0.5, unit: "cups"}} == extract_ingredient_fields("1/2 cups broccoli")
    end

    test "recognizes amounts of ingredients without units" do
      assert {:ok, %{name: "egg", amount: 1, unit: "egg"}} == extract_ingredient_fields("1 egg")
    end

    test "recognizes amounts of ingredients without units multi word" do
      assert {:ok, %{name: "green banana", amount: 1, unit: "green banana"}} == extract_ingredient_fields("1 egg")
    end

    test "provides the user an error when a unit is not provided" do
      assert {:error, _} = extract_ingredient_fields("1 flour")
    end

    test "parses a note in parenthesis at the end" do
      assert {:ok, %{name: "egg", note: "chopped"}} == extract_ingredient_fields("egg (chopped)")
    end

    test "considers parenthesis a part of the ingredient name when not at the end" do
      assert {:ok, %{name: "large (XXL) eggs"}} == extract_ingredient_fields("large (XXL) eggs")
    end
  end
end
