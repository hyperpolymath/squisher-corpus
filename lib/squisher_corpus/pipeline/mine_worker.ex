# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Pipeline.MineWorker do
  @moduledoc """
  Stage 4: Pattern mining across analyzed schemas.

  Runs periodically (every 6 hours by default) to cross-reference
  analysis results and discover common patterns. Compares schema pairs
  within the same repo for compatibility patterns.
  """

  use Oban.Worker, queue: :mine, max_attempts: 1

  alias SquisherCorpus.Repo
  alias SquisherCorpus.Schemas.{AnalysisResult, Pattern, ComparisonPair}
  alias SquisherCorpus.Mining.PatternDetector

  import Ecto.Query

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.info("MineWorker starting pattern mining run")

    results = load_analysis_results()

    if length(results) < 2 do
      Logger.info("MineWorker: not enough results to mine (#{length(results)})")
      :ok
    else
      mine_patterns(results)
      mine_comparisons(results)
      :ok
    end
  end

  defp load_analysis_results do
    AnalysisResult
    |> preload(:schema_file)
    |> Repo.all()
  end

  defp mine_patterns(results) do
    detected = PatternDetector.detect_all(results)

    for {pattern_type, pattern_data} <- detected do
      attrs = %{
        pattern_type: to_string(pattern_type),
        frequency: pattern_data.frequency,
        description: pattern_data.description,
        representative_schemas: pattern_data.representative_ids,
        confidence: pattern_data.confidence
      }

      # Upsert pattern
      case Repo.get_by(Pattern, pattern_type: to_string(pattern_type)) do
        nil ->
          %Pattern{} |> Pattern.changeset(attrs) |> Repo.insert!()

        existing ->
          existing |> Pattern.changeset(attrs) |> Repo.update!()
      end
    end

    Logger.info("MineWorker updated #{length(detected)} patterns")
  end

  defp mine_comparisons(results) do
    # Group by repo, compare schemas within the same repo
    by_repo =
      results
      |> Enum.group_by(fn r -> r.schema_file.github_repo_id end)
      |> Enum.filter(fn {_repo_id, files} -> length(files) >= 2 end)

    count =
      Enum.reduce(by_repo, 0, fn {_repo_id, repo_results}, acc ->
        pairs = for a <- repo_results, b <- repo_results, a.id < b.id, do: {a, b}
        compare_pairs(pairs)
        acc + length(pairs)
      end)

    Logger.info("MineWorker compared #{count} schema pairs")
  end

  defp compare_pairs(pairs) do
    for {a, b} <- pairs do
      a_classes = a.transport_classes || []
      b_classes = b.transport_classes || []

      forward_class = best_class(a_classes)
      reverse_class = best_class(b_classes)
      asymmetry = calculate_asymmetry(a_classes, b_classes)

      attrs = %{
        source_id: a.schema_file.id,
        target_id: b.schema_file.id,
        forward_class: forward_class,
        reverse_class: reverse_class,
        asymmetry_score: asymmetry
      }

      case Repo.get_by(ComparisonPair, source_id: a.schema_file.id, target_id: b.schema_file.id) do
        nil -> %ComparisonPair{} |> ComparisonPair.changeset(attrs) |> Repo.insert()
        existing -> existing |> ComparisonPair.changeset(attrs) |> Repo.update()
      end
    end
  end

  defp best_class(classes) do
    cond do
      "Concorde" in classes -> "Concorde"
      "Business" in classes -> "Business"
      "Economy" in classes -> "Economy"
      true -> "Wheelbarrow"
    end
  end

  defp calculate_asymmetry(a_classes, b_classes) do
    a_set = MapSet.new(a_classes)
    b_set = MapSet.new(b_classes)

    union = MapSet.union(a_set, b_set) |> MapSet.size()
    intersection = MapSet.intersection(a_set, b_set) |> MapSet.size()

    if union == 0, do: 0.0, else: 1.0 - intersection / union
  end

  @doc """
  Schedule a mining run.
  """
  def schedule do
    %{}
    |> __MODULE__.new()
    |> Oban.insert()
  end
end
