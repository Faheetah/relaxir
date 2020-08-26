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

    test "parses a note in parenthesis at the end" do
      assert {:ok, %{name: "egg", note: "chopped"}} == extract_ingredient_fields("egg, chopped")
    end

    test "ignores no note provided" do
      assert {:ok, %{name: "egg", note: "chopped"}} == extract_ingredient_fields("egg, chopped")
    end
  end

  describe "parse_amount/1" do
    test "returns :error if nothing found" do
      assert :error == parse_amount("a a")
    end

    test "returns amount found" do
      assert 1 == parse_amount("1")
    end

    test "returns fraction found" do
      assert 0.5 == parse_amount("1/2")
    end

    test "returns :error on bad numerator" do
      assert :error == parse_amount("a/1")
    end

    test "returns :error on bad denominator" do
      assert :error == parse_amount("1/a")
    end
  end
end