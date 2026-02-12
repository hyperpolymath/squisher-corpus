# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.PortRunner do
  @moduledoc """
  Wraps calls to the protocol-squisher CLI `corpus-analyze` subcommand.

  Writes schema content to a temp file, invokes the binary, parses JSON output.
  """

  require Logger

  @doc """
  Run corpus-analyze on the given content with a format hint.

  Returns `{:ok, map()}` with the parsed JSON output or `{:error, reason}`.
  """
  @spec analyze(binary(), String.t()) :: {:ok, map()} | {:error, term()}
  def analyze(content, format) do
    bin = Application.get_env(:squisher_corpus, :protocol_squisher_bin, "protocol-squisher")
    timeout = Application.get_env(:squisher_corpus, :analyze_timeout_ms, 30_000)

    with {:ok, tmp_path} <- write_temp_file(content, format),
         {:ok, output} <- run_command(bin, tmp_path, format, timeout) do
      File.rm(tmp_path)
      parse_output(output)
    else
      {:error, reason} = err ->
        Logger.warning("PortRunner.analyze failed: #{inspect(reason)}")
        err
    end
  end

  defp write_temp_file(content, format) do
    ext = format_to_extension(format)
    path = Path.join(System.tmp_dir!(), "squisher_corpus_#{:rand.uniform(999_999)}.#{ext}")

    case File.write(path, content) do
      :ok -> {:ok, path}
      {:error, reason} -> {:error, {:write_failed, reason}}
    end
  end

  defp run_command(bin, path, format, timeout) do
    args = ["corpus-analyze", "--input", path, "--format", format]

    task =
      Task.async(fn ->
        try do
          case System.cmd(bin, args, stderr_to_stdout: true) do
            {output, 0} -> {:ok, output}
            {output, code} -> {:error, {:exit_code, code, output}}
          end
        rescue
          e in ErlangError ->
            {:error, {:system_cmd_failed, Exception.message(e)}}
        end
      end)

    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      nil -> {:error, :timeout}
    end
  end

  defp parse_output(output) do
    case Jason.decode(output) do
      {:ok, data} -> {:ok, data}
      {:error, reason} -> {:error, {:json_parse_failed, reason, output}}
    end
  end

  defp format_to_extension(format) do
    case format do
      "protobuf" -> "proto"
      "avro" -> "avsc"
      "thrift" -> "thrift"
      "capnproto" -> "capnp"
      "flatbuffers" -> "fbs"
      "json-schema" -> "json"
      "jsonschema" -> "json"
      "rust" -> "rs"
      "python" -> "py"
      "rescript" -> "res"
      "bebop" -> "bop"
      "messagepack" -> "msgpack"
      _ -> "schema"
    end
  end
end
