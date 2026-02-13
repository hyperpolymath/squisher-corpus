<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
# Composer — Gleam Orchestration Engine

## Status: Scaffold complete

Composer provides typed contract schemas and pipeline orchestration for the
squisher-corpus ecosystem. It runs on BEAM alongside Observatory (Elixir)
for native interop.

## Architecture

```
Pipeline Steps  →  Runner (shell exec)  →  Step Outcomes
                                              ↓
                                          Bundler  →  RunBundle (archival)
```

## Contract Schemas (8 modules)

| Module | Status |
|--------|--------|
| `contracts/envelope.gleam` | Typed + JSON encode/decode |
| `contracts/plan.gleam` | Typed + JSON encode/decode |
| `contracts/receipt.gleam` | Typed + JSON encode/decode |
| `contracts/weather.gleam` | Typed + JSON encode/decode |
| `contracts/message_intent.gleam` | Typed + JSON encode/decode |
| `contracts/pack_manifest.gleam` | Typed + JSON encode/decode |
| `contracts/ambient_payload.gleam` | Typed + JSON encode/decode |
| `contracts/run_bundle.gleam` | Typed + JSON encode/decode |

## Pipeline Components

- `step_types.gleam` — Shared PipelineStep + StepOutcome types
- `pipeline.gleam` — Pipeline creation, execution, dry-run, rollback
- `runner.gleam` — Step execution via shell (Erlang FFI)
- `bundler.gleam` — Packages outcomes into RunBundle for archival

## Tests

22 tests covering:
- 8 contract roundtrip tests (construct → encode → verify fields)
- 6 pipeline tests (create, ordering, dry-run, rollback, step labels)
- 5 bundler tests (success, dry-run, failure, layout, retention)
- 3 composer smoke tests (version, schema names, contract check)

## Build

```bash
cd composer && gleam build && gleam test
```

## Next Steps

- [ ] Full JSON decoders for all contract fields (currently minimal)
- [ ] Real shell execution integration with HCT, clinician, observatory
- [ ] BEAM interop with Observatory Elixir workers
- [ ] Contract validation middleware
