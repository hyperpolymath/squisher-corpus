# SPDX-License-Identifier: PMPL-1.0-or-later

import Config

config :logger, level: :info

config :squisher_corpus, SquisherCorpus.Repo,
  database: Path.expand("../squisher_corpus.db", __DIR__),
  pool_size: 10
