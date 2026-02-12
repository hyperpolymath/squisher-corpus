# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Pipeline.FetchWorkerTest do
  use SquisherCorpus.DataCase

  alias SquisherCorpus.Pipeline.FetchWorker
  alias SquisherCorpus.Schemas.SchemaFile

  import SquisherCorpus.Fixtures

  describe "new/1" do
    test "creates a valid job changeset" do
      changeset =
        FetchWorker.new(%{
          "github_repo_id" => 1,
          "owner" => "test",
          "repo" => "test",
          "path" => "schema.proto",
          "sha" => "abc123",
          "format" => "protobuf"
        })

      assert changeset.valid?
    end
  end

  describe "deduplication" do
    test "skips files with existing SHA" do
      repo = github_repo_fixture()

      _existing =
        schema_file_fixture(%{
          github_repo: repo,
          sha: "existing_sha",
          format: "protobuf"
        })

      job = %Oban.Job{
        args: %{
          "github_repo_id" => repo.id,
          "owner" => repo.owner,
          "repo" => repo.name,
          "path" => "other/schema.proto",
          "sha" => "existing_sha",
          "format" => "protobuf"
        }
      }

      assert :ok = FetchWorker.perform(job)

      # Should still be just one schema file with that SHA
      assert Repo.aggregate(from(s in SchemaFile, where: s.sha == "existing_sha"), :count) == 1
    end
  end
end
