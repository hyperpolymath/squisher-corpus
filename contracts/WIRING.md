<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
# Contract Schema Wiring Status

Status of typed contract schemas across the squisher-corpus ecosystem.

## Schema Status

| Schema | Rust (serde) | Gleam (composer) | Elixir (observatory) | Status |
|--------|-------------|------------------|---------------------|--------|
| evidence-envelope | Defined | **Typed** | Planned | Wired |
| procedure-plan | Defined | **Typed** | Planned | Wired |
| receipt | Defined | **Typed** | Planned | Wired |
| system-weather | Defined | **Typed** | Planned | Wired |
| message-intent | Planned | **Typed** | Planned | Typed (Gleam) |
| pack-manifest | Planned | **Typed** | Planned | Typed (Gleam) |
| ambient-payload | Planned | **Typed** | Planned | Typed (Gleam) |
| run-bundle | Planned | **Typed** | Planned | Typed (Gleam) |

## Legend

- **Defined**: Full serde types in Rust crate
- **Typed**: Gleam types with JSON encode/decode in `composer/src/contracts/`
- **Planned**: Schema known but not yet implemented in that language
- **Wired**: Connected across 2+ implementations
- **Typed (Gleam)**: First typed implementation, previously unconnected

## Notes

The 4 previously unconnected schemas (message-intent, pack-manifest,
ambient-payload, run-bundle) now have their first typed implementation
in the Gleam composer module. Next step: wire them into Elixir observatory
workers and Rust tooling.
