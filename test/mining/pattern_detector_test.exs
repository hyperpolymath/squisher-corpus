# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Mining.PatternDetectorTest do
  use SquisherCorpus.DataCase

  alias SquisherCorpus.Mining.PatternDetector
  alias SquisherCorpus.Schemas.AnalysisResult

  import SquisherCorpus.Fixtures

  describe "detect_format_prevalence/1" do
    test "counts format distribution" do
      repo = github_repo_fixture()

      for _ <- 1..3 do
        sf = schema_file_fixture(%{github_repo: repo, format: "protobuf"})
        analysis_result_fixture(%{schema_file: sf})
      end

      for _ <- 1..2 do
        sf = schema_file_fixture(%{github_repo: repo, format: "avro"})
        analysis_result_fixture(%{schema_file: sf})
      end

      results =
        AnalysisResult
        |> Repo.all()
        |> Repo.preload(:schema_file)

      result = PatternDetector.detect_format_prevalence(results)

      assert result.frequency == 5
      assert result.confidence > 0.0
      assert String.contains?(result.description, "protobuf")
    end
  end

  describe "detect_all/1" do
    test "returns patterns for non-empty results" do
      repo = github_repo_fixture()

      for _ <- 1..3 do
        sf = schema_file_fixture(%{github_repo: repo})
        analysis_result_fixture(%{schema_file: sf})
      end

      results =
        AnalysisResult
        |> Repo.all()
        |> Repo.preload(:schema_file)

      patterns = PatternDetector.detect_all(results)

      assert is_list(patterns)
      assert length(patterns) > 0

      for {type, data} <- patterns do
        assert is_atom(type)
        assert is_map(data)
        assert Map.has_key?(data, :frequency)
        assert Map.has_key?(data, :confidence)
        assert Map.has_key?(data, :description)
      end
    end

    test "returns empty list for empty results" do
      assert PatternDetector.detect_all([]) == []
    end
  end

  describe "detect_field_name_patterns/1" do
    test "extracts field names from IR schemas" do
      repo = github_repo_fixture()

      for _ <- 1..3 do
        sf = schema_file_fixture(%{github_repo: repo})
        analysis_result_fixture(%{schema_file: sf})
      end

      results =
        AnalysisResult
        |> Repo.all()
        |> Repo.preload(:schema_file)

      result = PatternDetector.detect_field_name_patterns(results)
      assert result.frequency > 0
      assert String.contains?(result.description, "name")
    end
  end
end
