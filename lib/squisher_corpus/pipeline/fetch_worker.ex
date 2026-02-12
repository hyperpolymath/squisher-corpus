# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Pipeline.FetchWorker do
  @moduledoc """
  Stage 2: Download raw schema file content from GitHub.

  Fetches the raw file via GitHub's raw content URL, stores it in the
  schema_files table, deduplicates by SHA, and enqueues AnalyzeWorker.
  """

  use Oban.Worker, queue: :fetch, max_attempts: 3

  alias SquisherCorpus.{Repo, RateLimiter}
  alias SquisherCorpus.Schemas.SchemaFile

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "github_repo_id" => github_repo_id,
          "owner" => owner,
          "repo" => repo,
          "path" => path,
          "sha" => sha,
          "format" => format
        }
      }) do
    # Skip if we already have this file
    if Repo.get_by(SchemaFile, sha: sha) do
      Logger.debug("FetchWorker skipping duplicate SHA: #{sha}")
      :ok
    else
      fetch_and_store(github_repo_id, owner, repo, path, sha, format)
    end
  end

  defp fetch_and_store(github_repo_id, owner, repo, path, sha, format) do
    :ok = RateLimiter.acquire(:core)

    url = "https://raw.githubusercontent.com/#{owner}/#{repo}/HEAD/#{path}"

    token = Application.get_env(:squisher_corpus, :github_token)

    headers =
      [{"user-agent", "squisher-corpus/0.1"}] ++
        if(token, do: [{"authorization", "Bearer #{token}"}], else: [])

    case Req.get(url, headers: headers) do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        store_and_enqueue(github_repo_id, path, sha, format, body)

      {:ok, %Req.Response{status: 404}} ->
        Logger.debug("FetchWorker file not found: #{owner}/#{repo}/#{path}")
        :ok

      {:ok, %Req.Response{status: status}} ->
        Logger.warning("FetchWorker unexpected status #{status} for #{path}")
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        Logger.error("FetchWorker request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp store_and_enqueue(github_repo_id, path, sha, format, content) do
    attrs = %{
      github_repo_id: github_repo_id,
      path: path,
      sha: sha,
      format: format,
      raw_content: content,
      size_bytes: byte_size(content)
    }

    case %SchemaFile{} |> SchemaFile.changeset(attrs) |> Repo.insert() do
      {:ok, schema_file} ->
        Logger.info("FetchWorker stored #{path} (#{byte_size(content)} bytes)")

        %{"schema_file_id" => schema_file.id, "format" => format}
        |> SquisherCorpus.Pipeline.AnalyzeWorker.new()
        |> Oban.insert()

        :ok

      {:error, changeset} ->
        Logger.warning("FetchWorker insert failed: #{inspect(changeset.errors)}")
        :ok
    end
  end
end
