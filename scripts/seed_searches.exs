# SPDX-License-Identifier: PMPL-1.0-or-later
# Seed initial search queries across all supported formats.

alias SquisherCorpus.Pipeline.SearchWorker

IO.puts("Seeding search jobs for all supported formats...")

for {format, query} <- SearchWorker.search_queries() do
  IO.puts("  Enqueuing search for #{format}: #{query}")

  %{"format" => format, "page" => 1}
  |> SearchWorker.new()
  |> Oban.insert!()
end

IO.puts("Done! #{map_size(SearchWorker.search_queries())} search jobs enqueued.")
IO.puts("Start the application with `iex -S mix` to begin crawling.")
