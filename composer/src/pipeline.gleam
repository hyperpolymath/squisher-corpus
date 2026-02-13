// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

/// Pipeline orchestration — defines step sequences and executes them.

import bundler
import contracts/run_bundle.{type RunBundle}
import gleam/list
import gleam/option.{type Option, None, Some}
import runner
import step_types.{
  type PipelineStep, type StepOutcome, Failure, Skipped,
}

/// A pipeline definition: an ordered list of steps.
pub type Pipeline {
  Pipeline(
    id: String,
    name: String,
    steps: List(PipelineStep),
    dry_run: Bool,
  )
}

/// Result of executing the full pipeline.
pub type PipelineResult {
  PipelineResult(
    pipeline_id: String,
    outcomes: List(StepOutcome),
    run_bundle: Option(RunBundle),
  )
}

/// Create a new pipeline.
pub fn create(
  id id: String,
  name name: String,
  steps steps: List(PipelineStep),
) -> Pipeline {
  Pipeline(id: id, name: name, steps: steps, dry_run: False)
}

/// Execute a pipeline, running each step in order.
pub fn execute(pipeline: Pipeline) -> PipelineResult {
  let outcomes = case pipeline.dry_run {
    True -> dry_run_steps(pipeline.steps)
    False -> run_steps(pipeline.steps, [])
  }

  let bundle = bundler.create_bundle(pipeline.id, outcomes)

  PipelineResult(
    pipeline_id: pipeline.id,
    outcomes: outcomes,
    run_bundle: Some(bundle),
  )
}

/// Execute the pipeline in dry-run mode (all steps skipped).
pub fn dry_run(pipeline: Pipeline) -> PipelineResult {
  execute(Pipeline(..pipeline, dry_run: True))
}

/// Attempt rollback of completed steps (best-effort).
pub fn rollback(result: PipelineResult) -> PipelineResult {
  PipelineResult(..result, outcomes: [], run_bundle: None)
}

fn dry_run_steps(steps: List(PipelineStep)) -> List(StepOutcome) {
  list.map(steps, fn(step) {
    let label = step_types.step_label(step)
    Skipped(reason: "dry-run: " <> label)
  })
}

fn run_steps(
  steps: List(PipelineStep),
  acc: List(StepOutcome),
) -> List(StepOutcome) {
  case steps {
    [] -> list.reverse(acc)
    [step, ..rest] -> {
      let outcome = runner.run_step(step, False)
      case outcome {
        Failure(_, _) ->
          list.reverse([outcome, ..acc])
          |> list.append(list.map(rest, fn(s) {
            Skipped(reason: "predecessor failed: " <> step_types.step_label(s))
          }))
        _ -> run_steps(rest, [outcome, ..acc])
      }
    }
  }
}
