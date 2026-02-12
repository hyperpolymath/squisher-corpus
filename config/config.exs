# SPDX-License-Identifier: PMPL-1.0-or-later

import Config

config :squisher_corpus, SquisherCorpus.Repo,
  database: Path.expand("../squisher_corpus_#{config_env()}.db", __DIR__),
  pool_size: 5

config :squisher_corpus,
  ecto_repos: [SquisherCorpus.Repo]

config :squisher_corpus, Oban,
  repo: SquisherCorpus.Repo,
  engine: Oban.Engines.Lite,
  notifier: Oban.Notifiers.PG,
  queues: [
    search: 2,
    fetch: 5,
    analyze: 3,
    mine: 1,
    sync: 1
  ]

config :squisher_corpus,
  protocol_squisher_bin: System.get_env("PROTOCOL_SQUISHER_BIN", "protocol-squisher"),
  github_token: System.get_env("GITHUB_TOKEN"),
  analyze_timeout_ms: 30_000

import_config "#{config_env()}.exs"
