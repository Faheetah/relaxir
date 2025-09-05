defmodule RelaxirWeb.RecipeView do
  use RelaxirWeb, :view

  def parse_fraction(nil), do: nil

  # What does this do lol?
  # Looks like it turns a float into a human readable fraction
  def parse_fraction(amount) do
    # covers up to 1..100/1..100 reliably
    # can possibly cover up to 1/999999 reasonably well
    # reducing this can improve performance in case of DoS since :timer.tc 1/999999 = ~600ms
    denominator =
      1..9_999_999
      |> Enum.find(1, fn f ->
        # amount / 1 to force float, in case of amount = 1
        Float.floor(f * (amount / 1)) == f * amount
      end)

    numerator = trunc(amount * denominator)
    whole = trunc((numerator - rem(numerator, denominator)) / denominator)
    gcd = Integer.gcd(numerator, denominator)

    [whole, trunc(rem(numerator, denominator) / gcd), trunc(denominator / gcd)]
    |> case do
      [0, n, d] when n > 0 and d > 0 -> "#{n}/#{d}"
      [w, _, 1] -> w
      [w, n, d] -> "#{w} #{n}/#{d}"
    end
  end
end
