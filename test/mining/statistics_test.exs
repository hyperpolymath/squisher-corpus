# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Mining.StatisticsTest do
  use SquisherCorpus.DataCase

  alias SquisherCorpus.Mining.Statistics

  import SquisherCorpus.Fixtures

  describe "corpus_summary/0" do
    test "returns summary with zero counts on empty db" do
      summary = Statistics.corpus_summary()

      assert summary.totals.repos == 0
      assert summary.totals.schema_files == 0
      assert summary.totals.analysis_results == 0
    end

    test "returns correct counts with data" do
      repo = github_repo_fixture()
      sf = schema_file_fixture(%{github_repo: repo})
      analysis_result_fixture(%{schema_file: sf})

      summary = Statistics.corpus_summary()

      assert summary.totals.repos == 1
      assert summary.totals.schema_files == 1
      assert summary.totals.analysis_results == 1
    end
  end

  describe "format_distribution/0" do
    test "counts schemas by format" do
      repo = github_repo_fixture()
      schema_file_fixture(%{github_repo: repo, format: "protobuf"})
      schema_file_fixture(%{github_repo: repo, format: "protobuf"})
      schema_file_fixture(%{github_repo: repo, format: "avro"})

      dist = Statistics.format_distribution()

      assert dist["protobuf"] == 2
      assert dist["avro"] == 1
    end
  end

  describe "squishability_stats/0" do
    test "returns zero stats on empty db" do
      stats = Statistics.squishability_stats()
      assert stats.count == 0
    end

    test "computes correct stats" do
      repo = github_repo_fixture()

      for score <- [0.5, 0.7, 0.9] do
        sf = schema_file_fixture(%{github_repo: repo})
        analysis_result_fixture(%{schema_file: sf, squishability_score: score})
      end

      stats = Statistics.squishability_stats()

      assert stats.count == 3
      assert stats.min == 0.5
      assert stats.max == 0.9
      assert_in_delta stats.mean, 0.7, 0.01
    end
  end
end
