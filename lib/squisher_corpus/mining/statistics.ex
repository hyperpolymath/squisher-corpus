# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Mining.Statistics do
  @moduledoc """
  Corpus-wide statistics computation.

  Provides aggregate metrics over the entire corpus for export
  and analysis.
  """

  alias SquisherCorpus.Repo
  alias SquisherCorpus.Schemas.{GithubRepo, SchemaFile, AnalysisResult, Pattern, ComparisonPair}

  import Ecto.Query

  @doc """
  Generate a summary of the entire corpus.
  """
  def corpus_summary do
    %{
      generated_at: DateTime.utc_now(),
      totals: %{
        repos: Repo.aggregate(GithubRepo, :count),
        schema_files: Repo.aggregate(SchemaFile, :count),
        analysis_results: Repo.aggregate(AnalysisResult, :count),
        patterns: Repo.aggregate(Pattern, :count),
        comparison_pairs: Repo.aggregate(ComparisonPair, :count)
      },
      format_distribution: format_distribution(),
      squishability: squishability_stats(),
      transport_class_frequency: transport_class_frequency()
    }
  end

  @doc """
  Count schema files by format.
  """
  def format_distribution do
    SchemaFile
    |> group_by([s], s.format)
    |> select([s], {s.format, count(s.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Compute squishability score statistics.
  """
  def squishability_stats do
    scores =
      AnalysisResult
      |> select([a], a.squishability_score)
      |> where([a], not is_nil(a.squishability_score))
      |> Repo.all()

    if length(scores) == 0 do
      %{count: 0, mean: 0.0, median: 0.0, min: 0.0, max: 0.0, stddev: 0.0}
    else
      sorted = Enum.sort(scores)
      n = length(sorted)
      mean = Enum.sum(sorted) / n
      median = Enum.at(sorted, div(n, 2))
      min_v = List.first(sorted)
      max_v = List.last(sorted)

      variance = Enum.sum(Enum.map(sorted, fn s -> (s - mean) * (s - mean) end)) / n
      stddev = :math.sqrt(variance)

      %{
        count: n,
        mean: Float.round(mean, 4),
        median: Float.round(median, 4),
        min: Float.round(min_v, 4),
        max: Float.round(max_v, 4),
        stddev: Float.round(stddev, 4)
      }
    end
  end

  @doc """
  Count how often each transport class appears across all analyses.
  """
  def transport_class_frequency do
    AnalysisResult
    |> select([a], a.transport_classes)
    |> where([a], not is_nil(a.transport_classes))
    |> Repo.all()
    |> List.flatten()
    |> Enum.frequencies()
  end

  @doc """
  Compute empirical type frequency across all IR schemas.
  """
  def type_frequency do
    results =
      AnalysisResult
      |> select([a], a.ir_schema)
      |> where([a], not is_nil(a.ir_schema))
      |> Repo.all()

    type_counts =
      results
      |> Enum.flat_map(&extract_primitive_types/1)
      |> Enum.frequencies()
      |> Enum.sort_by(fn {_type, count} -> count end, :desc)
      |> Map.new()

    %{
      generated_at: DateTime.utc_now(),
      total_fields_analyzed: Enum.sum(Map.values(type_counts)),
      types: type_counts
    }
  end

  defp extract_primitive_types(%{"types" => types}) when is_map(types) do
    types
    |> Map.values()
    |> Enum.flat_map(fn
      %{"struct" => %{"fields" => fields}} when is_list(fields) ->
        Enum.map(fields, &extract_type_name/1)

      %{"Struct" => %{"fields" => fields}} when is_list(fields) ->
        Enum.map(fields, &extract_type_name/1)

      _ ->
        []
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp extract_primitive_types(_), do: []

  defp extract_type_name(%{"ty" => %{"Primitive" => prim}}) when is_binary(prim), do: prim
  defp extract_type_name(%{"ty" => %{"primitive" => prim}}) when is_binary(prim), do: prim
  defp extract_type_name(%{"ty" => %{"Container" => _}}), do: "Container"
  defp extract_type_name(%{"ty" => %{"container" => _}}), do: "Container"
  defp extract_type_name(%{"ty" => %{"Reference" => _}}), do: "Reference"
  defp extract_type_name(%{"ty" => %{"reference" => _}}), do: "Reference"
  defp extract_type_name(%{"ty" => %{"Special" => _}}), do: "Special"
  defp extract_type_name(%{"ty" => %{"special" => _}}), do: "Special"
  defp extract_type_name(_), do: nil
end
