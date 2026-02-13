// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

/// Receipt contract — records the outcome of executing a procedure plan.

import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

/// Overall receipt status.
pub type ReceiptStatus {
  Succeeded
  PartialSuccess
  Failed
  RolledBack
}

/// Status of an individual step execution.
pub type StepStatus {
  StepSucceeded
  StepFailed
  StepSkipped
  StepRolledBack
}

/// Undo bundle for rollback.
pub type UndoBundle {
  UndoBundle(
    step_id: String,
    command: String,
    args: List(String),
  )
}

/// Result of executing a single step.
pub type StepResult {
  StepResult(
    step_id: String,
    status: StepStatus,
    output: Option(String),
    error: Option(String),
    duration_ms: Int,
    undo: Option(UndoBundle),
  )
}

/// Top-level receipt.
pub type Receipt {
  Receipt(
    id: String,
    schema_version: String,
    plan_id: String,
    status: ReceiptStatus,
    step_results: List(StepResult),
    started_at: String,
    completed_at: String,
  )
}

/// Create a default receipt.
pub fn new() -> Receipt {
  Receipt(
    id: "",
    schema_version: "1.0.0",
    plan_id: "",
    status: Succeeded,
    step_results: [],
    started_at: "",
    completed_at: "",
  )
}

pub fn status_to_string(s: ReceiptStatus) -> String {
  case s {
    Succeeded -> "succeeded"
    PartialSuccess -> "partial_success"
    Failed -> "failed"
    RolledBack -> "rolled_back"
  }
}

pub fn status_from_string(s: String) -> Result(ReceiptStatus, Nil) {
  case s {
    "succeeded" -> Ok(Succeeded)
    "partial_success" -> Ok(PartialSuccess)
    "failed" -> Ok(Failed)
    "rolled_back" -> Ok(RolledBack)
    _ -> Error(Nil)
  }
}

pub fn step_status_to_string(s: StepStatus) -> String {
  case s {
    StepSucceeded -> "succeeded"
    StepFailed -> "failed"
    StepSkipped -> "skipped"
    StepRolledBack -> "rolled_back"
  }
}

pub fn step_result_to_json(sr: StepResult) -> Json {
  json.object([
    #("step_id", json.string(sr.step_id)),
    #("status", json.string(step_status_to_string(sr.status))),
    #("duration_ms", json.int(sr.duration_ms)),
  ])
}

/// Encode the full receipt to JSON.
pub fn to_json(r: Receipt) -> Json {
  json.object([
    #("id", json.string(r.id)),
    #("schema_version", json.string(r.schema_version)),
    #("plan_id", json.string(r.plan_id)),
    #("status", json.string(status_to_string(r.status))),
    #("step_results", json.array(r.step_results, step_result_to_json)),
    #("started_at", json.string(r.started_at)),
    #("completed_at", json.string(r.completed_at)),
  ])
}

/// Decoder for parsing a receipt from JSON.
pub fn decoder() -> decode.Decoder(Receipt) {
  use id <- decode.field("id", decode.string)
  use sv <- decode.field("schema_version", decode.string)
  use plan_id <- decode.field("plan_id", decode.string)
  decode.success(Receipt(
    id: id,
    schema_version: sv,
    plan_id: plan_id,
    status: Succeeded,
    step_results: [],
    started_at: "",
    completed_at: "",
  ))
}
