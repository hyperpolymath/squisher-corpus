// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

/// Step runner — executes individual pipeline steps via shell commands.
/// Calls HCT, clinician, observatory CLIs as needed.

import gleam/option.{None}
import gleam/string
import step_types.{
  type PipelineStep, type StepOutcome, Apply, Custom, Failure,
  GenerateWeather, Ingest, Plan, Scan, Skipped, Success,
}

/// Execute a single pipeline step.
/// When dry_run is True, the step is skipped rather than executed.
pub fn run_step(step: PipelineStep, dry_run: Bool) -> StepOutcome {
  case dry_run {
    True -> Skipped(reason: "dry-run: " <> step_types.step_label(step))
    False -> execute_step(step)
  }
}

fn execute_step(step: PipelineStep) -> StepOutcome {
  case step {
    Scan(device) ->
      run_command("panic-attack", ["assail", device, "--output", "/tmp/scan-" <> device <> ".json"])
    Plan(device, strategy) ->
      run_command("clinician", ["plan", "--device", device, "--strategy", strategy])
    Apply(plan_path) ->
      run_command("clinician", ["apply", "--plan", plan_path])
    Ingest(envelope_path) ->
      run_command("observatory", ["ingest", "--envelope", envelope_path])
    GenerateWeather ->
      run_command("observatory", ["weather", "--format", "json"])
    Custom(command, args) ->
      run_command(command, args)
  }
}

/// Run a shell command and return the outcome.
pub fn run_command(command: String, args: List(String)) -> StepOutcome {
  let full_cmd = command <> " " <> string.join(args, " ")
  case do_shell_exec(full_cmd) {
    Ok(output) -> Success(output: output, receipt_path: None)
    Error(err) -> Failure(error: err, rollback_available: False)
  }
}

/// Shell execution via Erlang interop.
@external(erlang, "composer_ffi", "shell_exec")
fn do_shell_exec(command: String) -> Result(String, String)
