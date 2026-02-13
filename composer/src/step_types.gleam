// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

/// Shared pipeline types — breaks circular dependencies between
/// pipeline, runner, and bundler.

import gleam/option.{type Option}

/// A pipeline step describing what action to take.
pub type PipelineStep {
  Scan(device: String)
  Plan(device: String, strategy: String)
  Apply(plan_path: String)
  Ingest(envelope_path: String)
  GenerateWeather
  Custom(command: String, args: List(String))
}

/// Outcome of executing a single step.
pub type StepOutcome {
  Success(output: String, receipt_path: Option(String))
  Failure(error: String, rollback_available: Bool)
  Skipped(reason: String)
}

/// Return a human-readable label for a step.
pub fn step_label(step: PipelineStep) -> String {
  case step {
    Scan(device) -> "scan(" <> device <> ")"
    Plan(device, strategy) ->
      "plan(" <> device <> ", " <> strategy <> ")"
    Apply(path) -> "apply(" <> path <> ")"
    Ingest(path) -> "ingest(" <> path <> ")"
    GenerateWeather -> "generate_weather"
    Custom(cmd, _) -> "custom(" <> cmd <> ")"
  }
}
