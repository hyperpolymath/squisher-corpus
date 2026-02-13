<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
# squisher-corpus — Project Instructions

## Build Commands

```bash
# Elixir (main app)
mix deps.get
mix ecto.create && mix ecto.migrate
mix test

# Gleam (composer)
cd composer && gleam build && gleam test
```

## Architecture

- **Elixir/Oban** — Pipeline workers (search, fetch, analyze, mine, sync)
- **Gleam/BEAM** — Composer orchestration engine (contract types, pipeline)
- **SQLite** — Local corpus storage via Ecto
- **protocol-squisher** — External CLI for schema analysis

## Key Paths

| Path | Purpose |
|------|---------|
| `lib/squisher_corpus/` | Elixir application code |
| `lib/squisher_corpus/pipeline/` | Oban workers (5 stages) |
| `lib/squisher_corpus/schemas/` | Ecto schemas |
| `composer/src/contracts/` | 8 Gleam contract type modules |
| `composer/src/pipeline.gleam` | Pipeline orchestration |
| `composer/src/bundler.gleam` | Run bundle packaging |
| `contracts/WIRING.md` | Schema wiring status |
| `.machine_readable/STATE.scm` | Project state tracking |

## Conventions

- Contract schemas: one Gleam module per schema in `composer/src/contracts/`
- All contracts have `new()` constructor, `to_json()` encoder, `decoder()` function
- Shared pipeline types in `composer/src/step_types.gleam`
- Within Gleam package: import without prefix (`import step_types` not `import composer/step_types`)
