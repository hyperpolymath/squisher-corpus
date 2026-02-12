# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Pipeline.SearchWorkerTest do
  use SquisherCorpus.DataCase

  alias SquisherCorpus.Pipeline.SearchWorker

  describe "search_queries/0" do
    test "returns queries for all supported formats" do
      queries = SearchWorker.search_queries()
      assert map_size(queries) >= 10

      assert Map.has_key?(queries, "protobuf")
      assert Map.has_key?(queries, "avro")
      assert Map.has_key?(queries, "thrift")
      assert Map.has_key?(queries, "serde")
      assert Map.has_key?(queries, "pydantic")
    end

    test "all queries are non-empty strings" do
      for {_format, query} <- SearchWorker.search_queries() do
        assert is_binary(query)
        assert String.length(query) > 0
      end
    end
  end

  describe "new/1" do
    test "creates a valid job changeset" do
      changeset = SearchWorker.new(%{"format" => "protobuf", "page" => 1})
      assert changeset.valid?
    end
  end
end
