# SPDX-License-Identifier: PMPL-1.0-or-later
# Export current patterns and statistics for protocol-squisher consumption.

alias SquisherCorpus.Pipeline.SyncWorker

IO.puts("Triggering sync/export...")

case SyncWorker.schedule() do
  {:ok, _job} ->
    IO.puts("SyncWorker job enqueued. Exports will be written to exports/ directory.")
    IO.puts("Run `iex -S mix` and wait for the job to complete, or run manually:")
    IO.puts("  SquisherCorpus.Pipeline.SyncWorker.perform(%Oban.Job{})")

  {:error, reason} ->
    IO.puts("Failed to enqueue: #{inspect(reason)}")
end
