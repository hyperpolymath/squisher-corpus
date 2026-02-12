# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Pipeline.SearchWorker do
  @moduledoc """
  Stage 1: GitHub code search for schema files.

  Searches the GitHub code API for schema files matching known patterns,
  rate-limited to 30 searches/min via the RateLimiter GenServer.
  Paginates up to 1000 results per query. Enqueues FetchWorker jobs
  for each discovered file.
  """

  use Oban.Worker, queue: :search, max_attempts: 3

  alias SquisherCorpus.{Repo, RateLimiter}
  alias SquisherCorpus.Schemas.GithubRepo

  require Logger

  @search_queries %{
    "protobuf" => ~s(syntax = "proto3"),
    "avro" => ~s("type" "record" extension:avsc),
    "thrift" => ~s(struct extension:thrift),
    "capnproto" => ~s(struct @0x extension:capnp),
    "flatbuffers" => ~s(table extension:fbs),
    "jsonschema" => ~s("$schema" "json-schema.org" extension:json),
    "pydantic" => ~s(class BaseModel extension:py),
    "serde" => ~s("#[derive(Serialize" extension:rs),
    "graphql" => ~s(type Query extension:graphql),
    "openapi" => ~s(openapi: "3" extension:yaml)
  }

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"format" => format, "page" => page}}) do
    query = Map.get(@search_queries, format)

    unless query do
      {:error, "Unknown format: #{format}"}
    else
      search_github(query, format, page)
    end
  end

  def perform(%Oban.Job{args: %{"format" => format}}) do
    perform(%Oban.Job{args: %{"format" => format, "page" => 1}})
  end

  defp search_github(query, format, page) do
    :ok = RateLimiter.acquire(:search)

    token = Application.get_env(:squisher_corpus, :github_token)

    url = "https://api.github.com/search/code"

    headers =
      [
        {"accept", "application/vnd.github.v3+json"},
        {"user-agent", "squisher-corpus/0.1"}
      ] ++
        if(token, do: [{"authorization", "Bearer #{token}"}], else: [])

    case Req.get(url,
           params: [q: query, per_page: 100, page: page],
           headers: headers
         ) do
      {:ok, %Req.Response{status: 200, headers: resp_headers, body: body}} ->
        RateLimiter.update_from_headers(:search, resp_headers)
        process_results(body, format, page)

      {:ok, %Req.Response{status: 403, headers: resp_headers}} ->
        RateLimiter.update_from_headers(:search, resp_headers)
        Logger.warning("SearchWorker rate limited for #{format} page #{page}")
        {:snooze, 60}

      {:ok, %Req.Response{status: 422}} ->
        Logger.warning("SearchWorker validation failed for query: #{query}")
        :ok

      {:ok, %Req.Response{status: status}} ->
        Logger.error("SearchWorker unexpected status #{status} for #{format}")
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        Logger.error("SearchWorker request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp process_results(%{"items" => items, "total_count" => total}, format, page) do
    Logger.info("SearchWorker found #{length(items)} items for #{format} (page #{page}, total #{total})")

    for item <- items do
      repo_data = item["repository"]
      owner = repo_data["owner"]["login"]
      name = repo_data["name"]

      # Upsert the GitHub repo
      github_repo =
        case Repo.get_by(GithubRepo, owner: owner, name: name) do
          nil ->
            %GithubRepo{}
            |> GithubRepo.changeset(%{
              owner: owner,
              name: name,
              stars: repo_data["stargazers_count"] || 0,
              language: repo_data["language"]
            })
            |> Repo.insert!()

          existing ->
            existing
        end

      # Enqueue fetch job
      %{
        "github_repo_id" => github_repo.id,
        "owner" => owner,
        "repo" => name,
        "path" => item["path"],
        "sha" => item["sha"],
        "format" => format
      }
      |> SquisherCorpus.Pipeline.FetchWorker.new()
      |> Oban.insert()
    end

    # Paginate if more results exist (up to 10 pages = 1000 results)
    if length(items) == 100 and page < 10 do
      %{"format" => format, "page" => page + 1}
      |> __MODULE__.new(schedule_in: 5)
      |> Oban.insert()
    end

    :ok
  end

  defp process_results(_body, format, page) do
    Logger.warning("SearchWorker got unexpected body for #{format} page #{page}")
    :ok
  end

  @doc """
  Enqueue search jobs for all supported formats.
  """
  def enqueue_all do
    for {format, _query} <- @search_queries do
      %{"format" => format, "page" => 1}
      |> __MODULE__.new()
      |> Oban.insert()
    end
  end

  def search_queries, do: @search_queries
end
