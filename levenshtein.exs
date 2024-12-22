# levenshtein.exs

Mix.install([
  {:benchee, "~> 1.0"}
])

defmodule Levenshtein do
  @moduledoc """
  Module for calculating Levenshtein distance.
  """

  @doc """
  Calculates the Levenshtein distance between two strings.
  """
  def distance(s1, s2) do
    m = String.length(s1)
    n = String.length(s2)

    # Initialize the matrix
    d =
      for i <- 0..m do
        for j <- 0..n, do: if(i == 0, do: j, else: if(j == 0, do: i, else: 0))
      end

    # Calculate distances
    Enum.reduce(1..m, d, fn i, acc ->
      Enum.reduce(1..n, acc, fn j, d ->
        cost = if String.at(s1, i - 1) == String.at(s2, j - 1), do: 0, else: 1
        # Default to empty list if nil
        prev_row = Enum.at(d, i - 1, [])
        current_row = Enum.at(d, i, [])

        new_distance =
          min(
            Enum.at(current_row, j - 1, m) + 1,
            min(
              Enum.at(prev_row, j, n) + 1,
              Enum.at(prev_row, j - 1, m + n) + cost
            )
          )

        List.update_at(d, i, fn row ->
          List.replace_at(row, j, new_distance)
        end)
      end)
    end)
    |> Enum.at(m, [])
    |> Enum.at(n, m + n)
  end

  @doc """
  Benchmarking test cases for Levenshtein distance.
  """
  def benchmark do
    test_cases = [
      {"kitten", "sitting"},
      {"flaw", "lawn"},
      {"saturday", "sunday"},
      {"", ""},
      {"", "a"},
      {"a", ""}
    ]

    for {s1, s2} <- test_cases do
      IO.puts("Distance between '#{s1}' and '#{s2}': #{distance(s1, s2)}")
    end

    Benchee.run(
      %{
        "levenshtein" => fn {s1, s2} -> distance(s1, s2) end
      },
      inputs: Enum.into(test_cases, %{}, fn {k, v} -> {k <> " to " <> v, {k, v}} end)
    )
  end
end

Levenshtein.benchmark()
