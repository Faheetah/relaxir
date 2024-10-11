defmodule Relaxir.RecipeParserTest do
  use ExUnit.Case, async: true
  import Relaxir.Ingredients.Parser

  describe "extract_ingredient_fields/1" do
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

    test "parses a note when starting with a number" do
      # guards against false positives when parsing complex amounts i.e. "1 1/2 cups"
      assert {:ok, %{name: "egg", note: "1 times"}} == extract_ingredient_fields("egg, 1 times")
    end

    test "parses a note when amount and single word ingredient" do
      # guards against false positives when parsing ingredients without units i.e. "1/4 onion, sliced"
      assert {:ok, %{amount: 0.25, name: "", unit: "onion", note: "sliced"}} == extract_ingredient_fields("1/4 onion, sliced")
    end

    test "parses a note when amount and multiple commas" do
      # guards against false positives when parsing ingredients without units i.e. "1/4 onion, sliced"
      assert {:ok, %{amount: 1, name: "", unit: "onion", note: "sliced, diced, and nice"}} ==
               extract_ingredient_fields("1 onion, sliced, diced, and nice")
    end

    test "parses an ingredient without a unit" do
      # guards against false positives when parsing complex amounts i.e. "1 1/2 cups"
      assert {:ok, %{amount: 1, name: "", unit: "egg"}} == extract_ingredient_fields("1 egg")
    end

    test "ignores no amount provided" do
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
