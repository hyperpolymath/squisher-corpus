# SPDX-License-Identifier: PMPL-1.0-or-later

import Config

config :squisher_corpus, SquisherCorpus.Repo,
  database: Path.expand("../squisher_corpus_test.db", __DIR__),
  pool_size: 1,
  pool: Ecto.Adapters.SQL.Sandbox

config :squisher_corpus, Oban, testing: :manual

config :logger, level: :warning
