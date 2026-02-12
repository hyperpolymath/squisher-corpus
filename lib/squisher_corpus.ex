# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus do
  @moduledoc """
  Empirical schema corpus for protocol-squisher.

  Crawls GitHub for real-world schema files, analyzes them with
  protocol-squisher's `corpus-analyze` subcommand, stores results
  in SQLite, and mines patterns for transport class optimization.
  """
end
