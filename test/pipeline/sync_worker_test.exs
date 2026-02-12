# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Pipeline.SyncWorkerTest do
  use SquisherCorpus.DataCase

  alias SquisherCorpus.Pipeline.SyncWorker

  import SquisherCorpus.Fixtures

  describe "perform/1" do
    test "generates export files" do
      repo = github_repo_fixture()
      sf = schema_file_fixture(%{github_repo: repo})
      analysis_result_fixture(%{schema_file: sf})

      assert :ok = SyncWorker.perform(%Oban.Job{args: %{}})

      assert File.exists?("exports/corpus_statistics.json")
      assert File.exists?("exports/pattern_catalog.json")
      assert File.exists?("exports/type_frequency.json")
      assert File.exists?("exports/hypatia_facts.lgt")

      # Verify JSON is valid
      {:ok, stats} =
        "exports/corpus_statistics.json" |> File.read!() |> Jason.decode()

      assert Map.has_key?(stats, "totals")

      # Clean up
      File.rm_rf!("exports")
    end
  end
end
