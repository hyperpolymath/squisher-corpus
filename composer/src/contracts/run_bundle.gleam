// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

/// Run bundle contract — packages pipeline results for archival and replay.

import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

/// Type of bundle.
pub type BundleType {
  Full
  Incremental
  Snapshot
  DryRun
}

/// Layout of the bundle contents.
pub type BundleLayout {
  BundleLayout(
    root: String,
    receipts_dir: String,
    artifacts_dir: String,
    logs_dir: String,
  )
}

/// Content reference within the bundle.
pub type BundleContent {
  BundleContent(
    path: String,
    media_type: String,
    size_bytes: Int,
  )
}

/// Retention policy for the bundle.
pub type RetentionPolicy {
  RetentionPolicy(
    keep_days: Int,
    compress: Bool,
    archive_to: Option(String),
  )
}

/// Top-level run bundle.
pub type RunBundle {
  RunBundle(
    id: String,
    schema_version: String,
    pipeline_id: String,
    bundle_type: BundleType,
    layout: BundleLayout,
    contents: List(BundleContent),
    retention: RetentionPolicy,
    created_at: String,
  )
}

/// Create a default run bundle.
pub fn new() -> RunBundle {
  RunBundle(
    id: "",
    schema_version: "1.0.0",
    pipeline_id: "",
    bundle_type: Full,
    layout: BundleLayout(
      root: ".",
      receipts_dir: "receipts",
      artifacts_dir: "artifacts",
      logs_dir: "logs",
    ),
    contents: [],
    retention: RetentionPolicy(
      keep_days: 30,
      compress: True,
      archive_to: None,
    ),
    created_at: "",
  )
}

pub fn bundle_type_to_string(t: BundleType) -> String {
  case t {
    Full -> "full"
    Incremental -> "incremental"
    Snapshot -> "snapshot"
    DryRun -> "dry_run"
  }
}

pub fn bundle_type_from_string(s: String) -> Result(BundleType, Nil) {
  case s {
    "full" -> Ok(Full)
    "incremental" -> Ok(Incremental)
    "snapshot" -> Ok(Snapshot)
    "dry_run" -> Ok(DryRun)
    _ -> Error(Nil)
  }
}

pub fn layout_to_json(l: BundleLayout) -> Json {
  json.object([
    #("root", json.string(l.root)),
    #("receipts_dir", json.string(l.receipts_dir)),
    #("artifacts_dir", json.string(l.artifacts_dir)),
    #("logs_dir", json.string(l.logs_dir)),
  ])
}

pub fn content_to_json(c: BundleContent) -> Json {
  json.object([
    #("path", json.string(c.path)),
    #("media_type", json.string(c.media_type)),
    #("size_bytes", json.int(c.size_bytes)),
  ])
}

pub fn retention_to_json(r: RetentionPolicy) -> Json {
  json.object([
    #("keep_days", json.int(r.keep_days)),
    #("compress", json.bool(r.compress)),
    #("archive_to", json.nullable(r.archive_to, json.string)),
  ])
}

/// Encode run bundle to JSON.
pub fn to_json(b: RunBundle) -> Json {
  json.object([
    #("id", json.string(b.id)),
    #("schema_version", json.string(b.schema_version)),
    #("pipeline_id", json.string(b.pipeline_id)),
    #("bundle_type", json.string(bundle_type_to_string(b.bundle_type))),
    #("layout", layout_to_json(b.layout)),
    #("contents", json.array(b.contents, content_to_json)),
    #("retention", retention_to_json(b.retention)),
    #("created_at", json.string(b.created_at)),
  ])
}

/// Decoder for parsing a run bundle from JSON.
pub fn decoder() -> decode.Decoder(RunBundle) {
  use id <- decode.field("id", decode.string)
  use sv <- decode.field("schema_version", decode.string)
  use pid <- decode.field("pipeline_id", decode.string)
  decode.success(RunBundle(
    id: id,
    schema_version: sv,
    pipeline_id: pid,
    bundle_type: Full,
    layout: BundleLayout(
      root: ".",
      receipts_dir: "receipts",
      artifacts_dir: "artifacts",
      logs_dir: "logs",
    ),
    contents: [],
    retention: RetentionPolicy(
      keep_days: 30,
      compress: True,
      archive_to: None,
    ),
    created_at: "",
  ))
}
