<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# squisher-corpus — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              GITHUB API                 │
                        │        (Code Search, Raw Fetch)         │
                        └───────────────────┬─────────────────────┘
                                            │ JSON / Raw Files
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           CORPUS PIPELINE (ELIXIR)      │
                        │    (Oban Workers, Ecto, System.cmd)     │
                        └──────────┬───────────────────┬──────────┘
                                   │                   │
                                   ▼                   ▼
                        ┌───────────────────────┐  ┌────────────────────────────────┐
                        │ ANALYZE STAGE         │  │ MINE & SYNC STAGE              │
                        │ - protocol-squisher   │  │ - Pattern Detection            │
                        │ - corpus-analyze      │  │ - Logtalk Fact Gen             │
                        │ - Result Parsing      │  │ - Sync to Hypatia              │
                        └──────────┬────────────┘  └──────────┬─────────────────────┘
                                   │                          │
                                   └────────────┬─────────────┘
                                                ▼
                        ┌─────────────────────────────────────────┐
                        │             DATA LAYER                  │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │ SQLite DB │  │ Pattern Catalog   │  │
                        │  │ (Schemas) │  │ (Confidence)      │  │
                        │  └───────────┘  └───────────────────┘  │
                        └───────────────────┬─────────────────────┘
                                            │
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           COMPOSER (GLEAM)              │
                        │      (Contract Types, Orchestration)    │
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Justfile Automation  .machine_readable/  │
                        │  Oban Dashboard       0-AI-MANIFEST.a2ml  │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
PIPELINE STAGES
  SearchWorker (GitHub)             ██████████ 100%    Code search API stable
  FetchWorker (Deduplication)       ██████████ 100%    SHA-based dedupe verified
  AnalyzeWorker (Squisher CLI)      ██████████ 100%    System.cmd integration stable
  Mine & Sync (Hypatia)             ██████░░░░  60%    Logtalk fact generation active

DATA & ORCHESTRATION
  SQLite Schema (Schemas/Results)   ██████████ 100%    Ecto migrations verified
  Composer (Gleam Engine)           ████░░░░░░  30%    Contract types prototyping
  Oban Job Management               ██████████ 100%    Parallel processing verified

REPO INFRASTRUCTURE
  Justfile Automation               ██████████ 100%    Standard build/test tasks
  .machine_readable/                ██████████ 100%    STATE tracking active
  Pattern Catalog Export            ████████░░  80%    Empirical data refining

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ███████░░░  ~70%   Core pipeline stable, Gleam maturing
```

## Key Dependencies

```
GitHub API ──────► Fetch Raw ──────► corpus-analyze ──────► Pattern Mine
     │                 │                   │                    │
     ▼                 ▼                   ▼                    ▼
Search Seed ────► SQLite Storage ──► Stats Export ────────► Hypatia Facts
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
