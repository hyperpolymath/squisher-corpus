# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Pipeline.MineWorkerTest do
  use SquisherCorpus.DataCase

  alias SquisherCorpus.Pipeline.MineWorker
  alias SquisherCorpus.Schemas.Pattern

  import SquisherCorpus.Fixtures

  describe "perform/1" do
    test "does nothing with fewer than 2 results" do
      repo = github_repo_fixture()
      sf = schema_file_fixture(%{github_repo: repo})
      analysis_result_fixture(%{schema_file: sf})

      assert :ok = MineWorker.perform(%Oban.Job{args: %{}})
      assert Repo.aggregate(Pattern, :count) == 0
    end

    test "creates patterns when enough results exist" do
      repo = github_repo_fixture()

      for _ <- 1..5 do
        sf = schema_file_fixture(%{github_repo: repo})
        analysis_result_fixture(%{schema_file: sf})
      end

      assert :ok = MineWorker.perform(%Oban.Job{args: %{}})
      assert Repo.aggregate(Pattern, :count) > 0
    end
  end
end
