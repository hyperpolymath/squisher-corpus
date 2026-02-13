// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

/// Composer: Gleam orchestration engine for squisher-corpus.
///
/// Provides typed contract schemas for the 8 core message types
/// (envelope, plan, receipt, weather, message-intent, pack-manifest,
/// ambient-payload, run-bundle) and a pipeline execution engine
/// that wires them together for end-to-end corpus processing.

import contracts/ambient_payload
import contracts/envelope
import contracts/message_intent
import contracts/pack_manifest
import contracts/plan
import contracts/receipt
import contracts/run_bundle
import contracts/weather

/// Return the composer version string.
pub fn version() -> String {
  "0.1.0"
}

/// List the names of all typed contract schemas.
pub fn schema_names() -> List(String) {
  [
    "evidence-envelope",
    "procedure-plan",
    "receipt",
    "system-weather",
    "message-intent",
    "pack-manifest",
    "ambient-payload",
    "run-bundle",
  ]
}

/// Smoke-check that all contract constructors produce valid defaults.
pub fn check_contracts() -> Bool {
  let _env = envelope.new()
  let _pl = plan.new()
  let _rc = receipt.new()
  let _wt = weather.new()
  let _mi = message_intent.new()
  let _pm = pack_manifest.new()
  let _ap = ambient_payload.new()
  let _rb = run_bundle.new()
  True
}
