defmodule RelaxirWeb.Components.FormattingComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias RelaxirWeb.FormattingComponents
  alias Relaxir.Units.Unit

  describe "date/1" do
    test "formats date correctly" do
      assigns = %{day: 15, month: 3, year: 2023}

      html = render_component(&FormattingComponents.date/1, assigns)

      assert html =~ "Mar 15, 2023"
    end

    test "works with all months" do
      months = [
        {1, "Jan"},
        {2, "Feb"},
        {3, "Mar"},
        {4, "Apr"},
        {5, "May"},
        {6, "Jun"},
        {7, "Jul"},
        {8, "Aug"},
        {9, "Sep"},
        {10, "Oct"},
        {11, "Nov"},
        {12, "Dec"}
      ]

      Enum.each(months, fn {month_num, month_name} ->
        assigns = %{day: 1, month: month_num, year: 2023}
        html = render_component(&FormattingComponents.date/1, assigns)
        assert html =~ "#{month_name} 1, 2023"
      end)
    end
  end

  describe "ingredient/1" do
    test "formats ingredient with amount and unit" do
      unit = %Unit{name: "cup"}
      assigns = %{name: "flour", amount: 2, unit: unit, note: nil}

      html = render_component(&FormattingComponents.ingredient/1, assigns)

      # Normalize whitespace in the HTML output
      normalized_html = html |> String.replace("\n", " ") |> String.replace(~r/\s+/, " ")
      assert normalized_html =~ "2 cups flour"
    end

    test "formats ingredient with singular unit" do
      unit = %Unit{name: "cup"}
      assigns = %{name: "flour", amount: 1, unit: unit, note: nil}

      html = render_component(&FormattingComponents.ingredient/1, assigns)

      # Normalize whitespace in the HTML output
      normalized_html = html |> String.replace("\n", " ") |> String.replace(~r/\s+/, " ")
      assert normalized_html =~ "1 cup flour"
    end

    test "formats ingredient without unit" do
      assigns = %{name: "eggs", amount: 3, unit: nil, note: nil}

      html = render_component(&FormattingComponents.ingredient/1, assigns)

      # Normalize whitespace in the HTML output
      normalized_html = html |> String.replace("\n", " ") |> String.replace(~r/\s+/, " ")
      assert normalized_html =~ "3 eggs"
    end

    test "formats ingredient with note" do
      unit = %Unit{name: "cup"}
      assigns = %{name: "flour", amount: 2, unit: unit, note: "sifted"}

      html = render_component(&FormattingComponents.ingredient/1, assigns)

      # Normalize whitespace in the HTML output
      normalized_html = html |> String.replace("\n", " ") |> String.replace(~r/\s+/, " ")
      assert normalized_html =~ "2 cups flour"
      assert normalized_html =~ "sifted"
    end

    test "formats ingredient with empty note" do
      unit = %Unit{name: "cup"}
      assigns = %{name: "flour", amount: 2, unit: unit, note: ""}

      html = render_component(&FormattingComponents.ingredient/1, assigns)

      # Normalize whitespace in the HTML output
      normalized_html = html |> String.replace("\n", " ") |> String.replace(~r/\s+/, " ")
      assert normalized_html =~ "2 cups flour"
      refute normalized_html =~ ","
    end

    test "formats ingredient with nil note" do
      unit = %Unit{name: "cup"}
      assigns = %{name: "flour", amount: 2, unit: unit, note: nil}

      html = render_component(&FormattingComponents.ingredient/1, assigns)

      # Normalize whitespace in the HTML output
      normalized_html = html |> String.replace("\n", " ") |> String.replace(~r/\s+/, " ")
      assert normalized_html =~ "2 cups flour"
      refute normalized_html =~ ","
    end
  end

  describe "parse_decimal_to_fraction/1" do
    test "converts whole numbers" do
      assert FormattingComponents.parse_decimal_to_fraction(1) == 1
      assert FormattingComponents.parse_decimal_to_fraction(5) == 5
    end

    test "converts simple fractions" do
      assert FormattingComponents.parse_decimal_to_fraction(0.5) == "1/2"
      assert FormattingComponents.parse_decimal_to_fraction(0.25) == "1/4"
      assert FormattingComponents.parse_decimal_to_fraction(0.75) == "3/4"
    end

    test "converts mixed numbers" do
      assert FormattingComponents.parse_decimal_to_fraction(1.5) == "1 1/2"
      assert FormattingComponents.parse_decimal_to_fraction(2.25) == "2 1/4"
    end

    test "handles nil" do
      assert FormattingComponents.parse_decimal_to_fraction(nil) == nil
    end

    test "converts complex fractions" do
      assert FormattingComponents.parse_decimal_to_fraction(0.333) == "333/1000"
      assert FormattingComponents.parse_decimal_to_fraction(0.166) == "83/500"
    end
  end
end
