# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Pipeline.AnalyzeWorker do
  @moduledoc """
  Stage 3: Run protocol-squisher corpus-analyze on fetched schema files.

  Calls the protocol-squisher CLI via PortRunner, parses the JSON output,
  and stores the analysis result. Handles analyzer failures gracefully
  since not all files will parse successfully.
  """

  use Oban.Worker, queue: :analyze, max_attempts: 2

  alias SquisherCorpus.{Repo, PortRunner}
  alias SquisherCorpus.Schemas.{SchemaFile, AnalysisResult}

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"schema_file_id" => schema_file_id, "format" => format}}) do
    schema_file = Repo.get!(SchemaFile, schema_file_id)

    # Skip if already analyzed
    if Repo.get_by(AnalysisResult, schema_file_id: schema_file_id) do
      Logger.debug("AnalyzeWorker skipping already-analyzed file #{schema_file_id}")
      :ok
    else
      analyze_file(schema_file, format)
    end
  end

  defp analyze_file(schema_file, format) do
    # Map corpus format names to protocol-squisher format names
    cli_format = normalize_format(format)

    case PortRunner.analyze(schema_file.raw_content, cli_format) do
      {:ok, data} ->
        store_result(schema_file.id, data)

      {:error, {:exit_code, _code, output}} ->
        Logger.debug("AnalyzeWorker parse failed for #{schema_file.path}: #{String.slice(output, 0, 200)}")
        :ok

      {:error, reason} ->
        Logger.warning("AnalyzeWorker failed for #{schema_file.path}: #{inspect(reason)}")
        :ok
    end
  end

  defp store_result(schema_file_id, data) do
    schema_data = data["schema"] || %{}
    squishability = data["squishability"] || %{}
    transport_classes = data["transport_classes"] || []

    field_count = count_fields(schema_data)
    type_diversity = count_type_diversity(schema_data)

    attrs = %{
      schema_file_id: schema_file_id,
      ir_schema: schema_data,
      squishability_score: squishability["confidence"] || 0.0,
      transport_classes: transport_classes,
      field_count: field_count,
      type_diversity: type_diversity
    }

    case %AnalysisResult{} |> AnalysisResult.changeset(attrs) |> Repo.insert() do
      {:ok, _result} ->
        Logger.info("AnalyzeWorker stored result for schema_file #{schema_file_id}")
        :ok

      {:error, changeset} ->
        Logger.warning("AnalyzeWorker insert failed: #{inspect(changeset.errors)}")
        :ok
    end
  end

  defp count_fields(%{"types" => types}) when is_map(types) do
    types
    |> Map.values()
    |> Enum.reduce(0, fn
      %{"struct" => %{"fields" => fields}}, acc when is_list(fields) -> acc + length(fields)
      %{"Struct" => %{"fields" => fields}}, acc when is_list(fields) -> acc + length(fields)
      _, acc -> acc
    end)
  end

  defp count_fields(_), do: 0

  defp count_type_diversity(%{"types" => types}) when is_map(types) do
    map_size(types)
  end

  defp count_type_diversity(_), do: 0

  defp normalize_format("pydantic"), do: "python"
  defp normalize_format("serde"), do: "rust"
  defp normalize_format("jsonschema"), do: "json-schema"
  defp normalize_format("capnproto"), do: "capnproto"
  defp normalize_format("graphql"), do: "json-schema"
  defp normalize_format("openapi"), do: "json-schema"
  defp normalize_format(f), do: f
end
