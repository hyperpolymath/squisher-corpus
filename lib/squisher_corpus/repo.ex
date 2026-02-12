# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.Repo do
  use Ecto.Repo,
    otp_app: :squisher_corpus,
    adapter: Ecto.Adapters.SQLite3
end
