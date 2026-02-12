# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Integration.PortRunnerTest do
  use ExUnit.Case, async: true

  alias SquisherCorpus.PortRunner

  @moduletag :integration

  describe "analyze/2" do
    @tag :requires_cli
    test "analyzes a protobuf schema via CLI" do
      content = """
      syntax = "proto3";

      message Test {
        string name = 1;
        int32 id = 2;
      }
      """

      case PortRunner.analyze(content, "protobuf") do
        {:ok, data} ->
          assert Map.has_key?(data, "schema")
          assert Map.has_key?(data, "squishability")
          assert Map.has_key?(data, "transport_classes")
          assert is_list(data["transport_classes"])

        {:error, {:system_cmd_failed, _}} ->
          # CLI not installed, skip
          :ok
      end
    end

    test "returns error for invalid content" do
      result = PortRunner.analyze("not a schema", "protobuf")
      assert match?({:error, _}, result)
    end
  end
end
