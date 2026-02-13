// SPDX-License-Identifier: PMPL-1.0-or-later

import bundler
import contracts/run_bundle
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import step_types.{Failure, Skipped, Success}

pub fn main() {
  gleeunit.main()
}

pub fn create_bundle_from_success_test() {
  let outcomes = [
    Success(output: "scan complete", receipt_path: Some("receipts/scan.json")),
    Success(output: "weather ok", receipt_path: None),
  ]
  let bundle = bundler.create_bundle("pipe-1", outcomes)
  bundle.pipeline_id |> should.equal("pipe-1")
  bundle.bundle_type |> should.equal(run_bundle.Full)
  list.length(bundle.contents) |> should.equal(2)
}

pub fn create_bundle_from_dry_run_test() {
  let outcomes = [
    Skipped(reason: "dry-run: scan(dev)"),
    Skipped(reason: "dry-run: generate_weather"),
  ]
  let bundle = bundler.create_bundle("dry-pipe", outcomes)
  bundle.bundle_type |> should.equal(run_bundle.DryRun)
  list.length(bundle.contents) |> should.equal(0)
}

pub fn create_bundle_with_failure_test() {
  let outcomes = [
    Success(output: "ok", receipt_path: None),
    Failure(error: "command not found", rollback_available: False),
  ]
  let bundle = bundler.create_bundle("fail-pipe", outcomes)
  list.length(bundle.contents) |> should.equal(2)
  case list.last(bundle.contents) {
    Ok(c) -> c.media_type |> should.equal("text/plain")
    Error(_) -> should.fail()
  }
}

pub fn bundle_default_layout_test() {
  let bundle = bundler.create_bundle("layout-test", [])
  bundle.layout.receipts_dir |> should.equal("receipts")
  bundle.layout.artifacts_dir |> should.equal("artifacts")
  bundle.layout.logs_dir |> should.equal("logs")
}

pub fn bundle_default_retention_test() {
  let bundle = bundler.create_bundle("ret-test", [])
  bundle.retention.keep_days |> should.equal(30)
  bundle.retention.compress |> should.be_true
  bundle.retention.archive_to |> should.equal(None)
}
