// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

/// Procedure plan contract — describes a sequence of steps to execute.

import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

/// Risk level for a plan or step.
pub type RiskLevel {
  Negligible
  Low
  Medium
  High
  Critical
}

/// Whether a step can be reversed.
pub type Reversibility {
  FullyReversible
  PartiallyReversible
  Irreversible
}

/// Action to perform in a step.
pub type StepAction {
  ShellCommand(command: String, args: List(String))
  ApiCall(endpoint: String, method: String)
  FileOperation(op: String, path: String)
}

/// A single step in the plan.
pub type PlanStep {
  PlanStep(
    id: String,
    name: String,
    action: StepAction,
    risk: RiskLevel,
    reversibility: Reversibility,
    depends_on: List(String),
  )
}

/// Top-level procedure plan.
pub type ProcedurePlan {
  ProcedurePlan(
    id: String,
    schema_version: String,
    name: String,
    description: String,
    steps: List(PlanStep),
    overall_risk: RiskLevel,
    dry_run: Bool,
    created_at: String,
  )
}

/// Create a default procedure plan.
pub fn new() -> ProcedurePlan {
  ProcedurePlan(
    id: "",
    schema_version: "1.0.0",
    name: "",
    description: "",
    steps: [],
    overall_risk: Negligible,
    dry_run: False,
    created_at: "",
  )
}

pub fn risk_to_string(r: RiskLevel) -> String {
  case r {
    Negligible -> "negligible"
    Low -> "low"
    Medium -> "medium"
    High -> "high"
    Critical -> "critical"
  }
}

pub fn risk_from_string(s: String) -> Result(RiskLevel, Nil) {
  case s {
    "negligible" -> Ok(Negligible)
    "low" -> Ok(Low)
    "medium" -> Ok(Medium)
    "high" -> Ok(High)
    "critical" -> Ok(Critical)
    _ -> Error(Nil)
  }
}

pub fn reversibility_to_string(r: Reversibility) -> String {
  case r {
    FullyReversible -> "fully_reversible"
    PartiallyReversible -> "partially_reversible"
    Irreversible -> "irreversible"
  }
}

fn action_to_json(a: StepAction) -> Json {
  case a {
    ShellCommand(cmd, args) ->
      json.object([
        #("type", json.string("shell_command")),
        #("command", json.string(cmd)),
        #("args", json.array(args, json.string)),
      ])
    ApiCall(endpoint, method) ->
      json.object([
        #("type", json.string("api_call")),
        #("endpoint", json.string(endpoint)),
        #("method", json.string(method)),
      ])
    FileOperation(op, path) ->
      json.object([
        #("type", json.string("file_operation")),
        #("op", json.string(op)),
        #("path", json.string(path)),
      ])
  }
}

pub fn step_to_json(s: PlanStep) -> Json {
  json.object([
    #("id", json.string(s.id)),
    #("name", json.string(s.name)),
    #("action", action_to_json(s.action)),
    #("risk", json.string(risk_to_string(s.risk))),
    #("reversibility", json.string(reversibility_to_string(s.reversibility))),
    #("depends_on", json.array(s.depends_on, json.string)),
  ])
}

/// Encode the full plan to JSON.
pub fn to_json(p: ProcedurePlan) -> Json {
  json.object([
    #("id", json.string(p.id)),
    #("schema_version", json.string(p.schema_version)),
    #("name", json.string(p.name)),
    #("description", json.string(p.description)),
    #("steps", json.array(p.steps, step_to_json)),
    #("overall_risk", json.string(risk_to_string(p.overall_risk))),
    #("dry_run", json.bool(p.dry_run)),
    #("created_at", json.string(p.created_at)),
  ])
}

/// Decoder for parsing a plan from JSON.
pub fn decoder() -> decode.Decoder(ProcedurePlan) {
  use id <- decode.field("id", decode.string)
  use sv <- decode.field("schema_version", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(ProcedurePlan(
    id: id,
    schema_version: sv,
    name: name,
    description: "",
    steps: [],
    overall_risk: Negligible,
    dry_run: False,
    created_at: "",
  ))
}
