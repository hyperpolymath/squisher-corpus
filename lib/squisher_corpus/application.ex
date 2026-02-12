# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Application do
  @moduledoc """
  OTP Application supervisor for squisher-corpus.

  Starts the Ecto repo, Oban job queue, and rate limiter GenServer.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SquisherCorpus.Repo,
      {Oban, Application.fetch_env!(:squisher_corpus, Oban)},
      SquisherCorpus.RateLimiter
    ]

    opts = [strategy: :one_for_one, name: SquisherCorpus.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
