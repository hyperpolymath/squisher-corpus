// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

/// Evidence envelope contract — wraps scan artifacts, findings, and source metadata.

import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

/// Severity level for a finding.
pub type FindingSeverity {
  Critical
  High
  Medium
  Low
  Info
}

/// A single finding within the envelope.
pub type Finding {
  Finding(
    id: String,
    severity: FindingSeverity,
    title: String,
    description: String,
    location: Option(String),
  )
}

/// Which tool produced the evidence.
pub type SourceTool {
  SourceTool(name: String, version: String)
}

/// Origin of the evidence.
pub type EnvelopeSource {
  EnvelopeSource(
    repo: String,
    ref: Option(String),
    tool: SourceTool,
  )
}

/// An artifact attached to the envelope.
pub type Artifact {
  Artifact(
    path: String,
    media_type: String,
    sha256: Option(String),
  )
}

/// Top-level evidence envelope.
pub type EvidenceEnvelope {
  EvidenceEnvelope(
    id: String,
    schema_version: String,
    created_at: String,
    source: EnvelopeSource,
    findings: List(Finding),
    artifacts: List(Artifact),
  )
}

/// Create a default evidence envelope.
pub fn new() -> EvidenceEnvelope {
  EvidenceEnvelope(
    id: "",
    schema_version: "1.0.0",
    created_at: "",
    source: EnvelopeSource(
      repo: "",
      ref: None,
      tool: SourceTool(name: "", version: ""),
    ),
    findings: [],
    artifacts: [],
  )
}

pub fn severity_to_string(s: FindingSeverity) -> String {
  case s {
    Critical -> "critical"
    High -> "high"
    Medium -> "medium"
    Low -> "low"
    Info -> "info"
  }
}

pub fn severity_from_string(s: String) -> Result(FindingSeverity, Nil) {
  case s {
    "critical" -> Ok(Critical)
    "high" -> Ok(High)
    "medium" -> Ok(Medium)
    "low" -> Ok(Low)
    "info" -> Ok(Info)
    _ -> Error(Nil)
  }
}

pub fn finding_to_json(f: Finding) -> Json {
  let base = [
    #("id", json.string(f.id)),
    #("severity", json.string(severity_to_string(f.severity))),
    #("title", json.string(f.title)),
    #("description", json.string(f.description)),
  ]
  let with_location = case f.location {
    Some(loc) -> list.append(base, [#("location", json.string(loc))])
    None -> base
  }
  json.object(with_location)
}

pub fn artifact_to_json(a: Artifact) -> Json {
  let base = [
    #("path", json.string(a.path)),
    #("media_type", json.string(a.media_type)),
  ]
  let with_sha = case a.sha256 {
    Some(sha) -> list.append(base, [#("sha256", json.string(sha))])
    None -> base
  }
  json.object(with_sha)
}

/// Encode the full envelope to JSON.
pub fn to_json(env: EvidenceEnvelope) -> Json {
  json.object([
    #("id", json.string(env.id)),
    #("schema_version", json.string(env.schema_version)),
    #("created_at", json.string(env.created_at)),
    #("source", json.object([
      #("repo", json.string(env.source.repo)),
      #("tool", json.object([
        #("name", json.string(env.source.tool.name)),
        #("version", json.string(env.source.tool.version)),
      ])),
    ])),
    #("findings", json.array(env.findings, finding_to_json)),
    #("artifacts", json.array(env.artifacts, artifact_to_json)),
  ])
}

/// Decoder for parsing an envelope from JSON.
pub fn decoder() -> decode.Decoder(EvidenceEnvelope) {
  use id <- decode.field("id", decode.string)
  use sv <- decode.field("schema_version", decode.string)
  use ca <- decode.field("created_at", decode.string)
  decode.success(EvidenceEnvelope(
    id: id,
    schema_version: sv,
    created_at: ca,
    source: EnvelopeSource(
      repo: "",
      ref: None,
      tool: SourceTool(name: "", version: ""),
    ),
    findings: [],
    artifacts: [],
  ))
}
