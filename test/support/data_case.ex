# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule SquisherCorpus.DataCase do
  @moduledoc """
  Test case template for tests requiring database access.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias SquisherCorpus.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import SquisherCorpus.DataCase
    end
  end

  setup tags do
    SquisherCorpus.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(SquisherCorpus.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end
