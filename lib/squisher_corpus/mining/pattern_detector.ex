# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Mining.PatternDetector do
  @moduledoc """
  Cross-schema pattern detection.

  Analyzes accumulated analysis results to find recurring patterns:
  - Format prevalence
  - Type distribution
  - Nesting depth distribution
  - Optional vs required ratio
  - Cross-format pairs in same repo
  - Squishability distribution
  - Transport class frequency
  - Common field name patterns
  """

  @doc """
  Run all pattern detectors on the given analysis results.
  Returns a keyword list of {pattern_type, pattern_data}.
  """
  def detect_all(results) do
    [
      {:format_prevalence, detect_format_prevalence(results)},
      {:type_distribution, detect_type_distribution(results)},
      {:nesting_depth, detect_nesting_depth(results)},
      {:optional_ratio, detect_optional_ratio(results)},
      {:cross_format_pair, detect_cross_format_pairs(results)},
      {:field_name_pattern, detect_field_name_patterns(results)}
    ]
    |> Enum.filter(fn {_k, v} -> v.frequency > 0 end)
  end

  @doc """
  Detect which schema formats appear most frequently.
  """
  def detect_format_prevalence(results) do
    format_counts =
      results
      |> Enum.map(fn r -> r.schema_file && r.schema_file.format end)
      |> Enum.reject(&is_nil/1)
      |> Enum.frequencies()

    total = Enum.sum(Map.values(format_counts))

    top_formats =
      format_counts
      |> Enum.sort_by(fn {_f, c} -> c end, :desc)
      |> Enum.take(5)
      |> Enum.map(fn {f, c} -> "#{f}: #{c}" end)
      |> Enum.join(", ")

    %{
      frequency: total,
      description: "Format distribution: #{top_formats}",
      confidence: if(total > 10, do: 0.9, else: 0.5),
      representative_ids: results |> Enum.take(5) |> Enum.map(& &1.schema_file_id)
    }
  end

  @doc """
  Detect type diversity distribution across schemas.
  """
  def detect_type_distribution(results) do
    diversities =
      results
      |> Enum.map(fn r -> r.type_diversity || 0 end)
      |> Enum.reject(&(&1 == 0))

    if length(diversities) == 0 do
      %{frequency: 0, description: "No type data", confidence: 0.0, representative_ids: []}
    else
      avg = Enum.sum(diversities) / length(diversities)
      max_d = Enum.max(diversities)

      %{
        frequency: length(diversities),
        description: "Avg type diversity: #{Float.round(avg, 1)}, max: #{max_d}",
        confidence: if(length(diversities) > 5, do: 0.8, else: 0.4),
        representative_ids: results |> Enum.take(5) |> Enum.map(& &1.schema_file_id)
      }
    end
  end

  @doc """
  Detect nesting depth patterns from IR schemas.
  """
  def detect_nesting_depth(results) do
    depths =
      results
      |> Enum.map(fn r -> estimate_nesting_depth(r.ir_schema) end)
      |> Enum.reject(&(&1 == 0))

    if length(depths) == 0 do
      %{frequency: 0, description: "No nesting data", confidence: 0.0, representative_ids: []}
    else
      avg = Enum.sum(depths) / length(depths)

      %{
        frequency: length(depths),
        description: "Avg nesting depth: #{Float.round(avg, 1)}, max: #{Enum.max(depths)}",
        confidence: if(length(depths) > 5, do: 0.7, else: 0.3),
        representative_ids: results |> Enum.take(5) |> Enum.map(& &1.schema_file_id)
      }
    end
  end

  @doc """
  Detect the ratio of optional to required fields.
  """
  def detect_optional_ratio(results) do
    ratios =
      results
      |> Enum.map(fn r -> estimate_optional_ratio(r.ir_schema) end)
      |> Enum.reject(&is_nil/1)

    if length(ratios) == 0 do
      %{frequency: 0, description: "No optional ratio data", confidence: 0.0, representative_ids: []}
    else
      avg = Enum.sum(ratios) / length(ratios)

      %{
        frequency: length(ratios),
        description: "Avg optional ratio: #{Float.round(avg * 100, 1)}%",
        confidence: if(length(ratios) > 5, do: 0.8, else: 0.4),
        representative_ids: results |> Enum.take(5) |> Enum.map(& &1.schema_file_id)
      }
    end
  end

  @doc """
  Detect cross-format pairs appearing in the same repository.
  """
  def detect_cross_format_pairs(results) do
    by_repo =
      results
      |> Enum.group_by(fn r -> r.schema_file && r.schema_file.github_repo_id end)
      |> Map.delete(nil)

    cross_pairs =
      by_repo
      |> Enum.flat_map(fn {_repo_id, repo_results} ->
        formats = repo_results |> Enum.map(fn r -> r.schema_file.format end) |> Enum.uniq()

        if length(formats) >= 2 do
          for a <- formats, b <- formats, a < b, do: {a, b}
        else
          []
        end
      end)
      |> Enum.frequencies()

    if map_size(cross_pairs) == 0 do
      %{frequency: 0, description: "No cross-format pairs", confidence: 0.0, representative_ids: []}
    else
      top =
        cross_pairs
        |> Enum.sort_by(fn {_pair, c} -> c end, :desc)
        |> Enum.take(3)
        |> Enum.map(fn {{a, b}, c} -> "#{a}+#{b}: #{c}" end)
        |> Enum.join(", ")

      %{
        frequency: Enum.sum(Map.values(cross_pairs)),
        description: "Cross-format pairs: #{top}",
        confidence: 0.7,
        representative_ids: results |> Enum.take(5) |> Enum.map(& &1.schema_file_id)
      }
    end
  end

  @doc """
  Detect common field name patterns across schemas.
  """
  def detect_field_name_patterns(results) do
    field_names =
      results
      |> Enum.flat_map(fn r -> extract_field_names(r.ir_schema) end)
      |> Enum.frequencies()
      |> Enum.sort_by(fn {_name, count} -> count end, :desc)
      |> Enum.take(20)

    if length(field_names) == 0 do
      %{frequency: 0, description: "No field names", confidence: 0.0, representative_ids: []}
    else
      top =
        field_names
        |> Enum.take(5)
        |> Enum.map(fn {name, count} -> "#{name}: #{count}" end)
        |> Enum.join(", ")

      %{
        frequency: length(field_names),
        description: "Common fields: #{top}",
        confidence: if(length(field_names) > 10, do: 0.85, else: 0.5),
        representative_ids: results |> Enum.take(5) |> Enum.map(& &1.schema_file_id)
      }
    end
  end

  # Private helpers

  defp estimate_nesting_depth(%{"types" => types}) when is_map(types) do
    types
    |> Map.values()
    |> Enum.map(&count_references/1)
    |> Enum.max(fn -> 0 end)
  end

  defp estimate_nesting_depth(_), do: 0

  defp count_references(%{"struct" => %{"fields" => fields}}) when is_list(fields) do
    fields
    |> Enum.count(fn f ->
      ty = f["ty"] || f["type"] || %{}
      is_map(ty) and (Map.has_key?(ty, "Reference") or Map.has_key?(ty, "reference"))
    end)
  end

  defp count_references(_), do: 0

  defp estimate_optional_ratio(%{"types" => types}) when is_map(types) do
    fields =
      types
      |> Map.values()
      |> Enum.flat_map(fn
        %{"struct" => %{"fields" => fields}} when is_list(fields) -> fields
        %{"Struct" => %{"fields" => fields}} when is_list(fields) -> fields
        _ -> []
      end)

    total = length(fields)

    if total == 0 do
      nil
    else
      optional = Enum.count(fields, fn f -> f["optional"] == true end)
      optional / total
    end
  end

  defp estimate_optional_ratio(_), do: nil

  defp extract_field_names(%{"types" => types}) when is_map(types) do
    types
    |> Map.values()
    |> Enum.flat_map(fn
      %{"struct" => %{"fields" => fields}} when is_list(fields) ->
        Enum.map(fields, fn f -> f["name"] end) |> Enum.reject(&is_nil/1)

      %{"Struct" => %{"fields" => fields}} when is_list(fields) ->
        Enum.map(fields, fn f -> f["name"] end) |> Enum.reject(&is_nil/1)

      _ ->
        []
    end)
  end

  defp extract_field_names(_), do: []
end
