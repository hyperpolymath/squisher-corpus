# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Pipeline.AnalyzeWorkerTest do
  use SquisherCorpus.DataCase

  alias SquisherCorpus.Pipeline.AnalyzeWorker
  alias SquisherCorpus.Schemas.AnalysisResult

  import SquisherCorpus.Fixtures

  describe "perform/1" do
    test "skips already-analyzed files" do
      result = analysis_result_fixture()

      job = %Oban.Job{
        args: %{
          "schema_file_id" => result.schema_file_id,
          "format" => "protobuf"
        }
      }

      assert :ok = AnalyzeWorker.perform(job)

      # Should still be just one result
      assert Repo.aggregate(
               from(a in AnalysisResult, where: a.schema_file_id == ^result.schema_file_id),
               :count
             ) == 1
    end
  end

  describe "new/1" do
    test "creates a valid job changeset" do
      changeset = AnalyzeWorker.new(%{"schema_file_id" => 1, "format" => "protobuf"})
      assert changeset.valid?
    end
  end
end
