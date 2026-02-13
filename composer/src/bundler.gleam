// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

/// Bundler — packages pipeline results into a RunBundle for archival.

import contracts/run_bundle.{
  type BundleContent, type BundleLayout, type RetentionPolicy,
  type RunBundle, BundleContent, BundleLayout, RetentionPolicy,
  RunBundle,
}
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import step_types.{type StepOutcome, Failure, Skipped, Success}

/// Create a run bundle from pipeline outcomes.
pub fn create_bundle(
  pipeline_id: String,
  outcomes: List(StepOutcome),
) -> RunBundle {
  let contents =
    outcomes
    |> list.index_map(fn(outcome, idx) { outcome_to_content(outcome, idx) })
    |> list.filter_map(fn(x) { x })

  let bundle_type = case list.any(outcomes, fn(o) {
    case o {
      Skipped(reason) -> string.starts_with(reason, "dry-run:")
      _ -> False
    }
  }) {
    True -> run_bundle.DryRun
    False -> run_bundle.Full
  }

  RunBundle(
    id: pipeline_id <> "-bundle",
    schema_version: "1.0.0",
    pipeline_id: pipeline_id,
    bundle_type: bundle_type,
    layout: default_layout(),
    contents: contents,
    retention: default_retention(),
    created_at: "",
  )
}

/// Write a bundle manifest to the given output directory.
pub fn write_bundle(
  bundle: RunBundle,
  output_dir: String,
) -> Result(String, String) {
  let manifest_path = output_dir <> "/" <> bundle.id <> ".json"
  let json_str = run_bundle.to_json(bundle) |> json.to_string
  case do_write_file(manifest_path, json_str) {
    Ok(_) -> Ok(manifest_path)
    Error(e) -> Error("Failed to write bundle: " <> e)
  }
}

fn default_layout() -> BundleLayout {
  BundleLayout(
    root: ".",
    receipts_dir: "receipts",
    artifacts_dir: "artifacts",
    logs_dir: "logs",
  )
}

fn default_retention() -> RetentionPolicy {
  RetentionPolicy(
    keep_days: 30,
    compress: True,
    archive_to: None,
  )
}

fn outcome_to_content(
  outcome: StepOutcome,
  index: Int,
) -> Result(BundleContent, Nil) {
  let idx_str = string.inspect(index)
  case outcome {
    Success(output, receipt_path) -> {
      let path = case receipt_path {
        Some(p) -> p
        None -> "receipts/step-" <> idx_str <> ".json"
      }
      Ok(BundleContent(
        path: path,
        media_type: "application/json",
        size_bytes: string.byte_size(output),
      ))
    }
    Failure(error, _) ->
      Ok(BundleContent(
        path: "logs/step-" <> idx_str <> "-error.log",
        media_type: "text/plain",
        size_bytes: string.byte_size(error),
      ))
    Skipped(_) -> Error(Nil)
  }
}

/// Write a file to disk via Erlang interop.
@external(erlang, "composer_ffi", "write_file")
fn do_write_file(path: String, content: String) -> Result(String, String)
