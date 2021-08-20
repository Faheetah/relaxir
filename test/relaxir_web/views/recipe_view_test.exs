defmodule RelaxirWeb.RecipeViewTest do
  use RelaxirWeb.ConnCase, async: true

  describe "parse_fraction/1" do
    test "gets valid results up to 1..100/1..100" do
      nums =
        for i <- 1..100, j <- 1..100 do
          a = RelaxirWeb.RecipeView.parse_fraction(i / j)
          whole = trunc((i - rem(i, j)) / j)
          fraction = rem(i, j)
          gcd = Integer.gcd(fraction, j)
          n = trunc(fraction / gcd)
          d = trunc(j / gcd)

          [whole, n]
          |> case do
            [0, _] -> {a, "#{n}/#{d}"}
            [_, 0] -> {a, whole}
            _ -> {a, "#{whole} #{n}/#{d}"}
          end
        end
        |> Enum.reject(fn {i, j} -> i == j end)

      assert nums == []
    end
  end
end
