// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

/// Pack manifest contract — describes a distributable pack of tools/assets.

import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

/// Target platform for the pack.
pub type PackPlatform {
  PackPlatform(
    os: String,
    arch: String,
    variant: Option(String),
  )
}

/// A check the pack must pass.
pub type PackCheck {
  PackCheck(
    name: String,
    command: String,
    expected_exit: Int,
  )
}

/// An action the pack can execute.
pub type PackAction {
  PackAction(
    name: String,
    command: String,
    args: List(String),
    description: String,
  )
}

/// Claims the pack makes about its properties.
pub type PackClaims {
  PackClaims(
    signed: Bool,
    reproducible: Bool,
    sbom_included: Bool,
    provenance: Option(String),
  )
}

/// Top-level pack manifest.
pub type PackManifest {
  PackManifest(
    id: String,
    schema_version: String,
    name: String,
    version: String,
    platforms: List(PackPlatform),
    checks: List(PackCheck),
    actions: List(PackAction),
    claims: PackClaims,
    created_at: String,
  )
}

/// Create a default pack manifest.
pub fn new() -> PackManifest {
  PackManifest(
    id: "",
    schema_version: "1.0.0",
    name: "",
    version: "0.0.0",
    platforms: [],
    checks: [],
    actions: [],
    claims: PackClaims(
      signed: False,
      reproducible: False,
      sbom_included: False,
      provenance: None,
    ),
    created_at: "",
  )
}

pub fn platform_to_json(p: PackPlatform) -> Json {
  json.object([
    #("os", json.string(p.os)),
    #("arch", json.string(p.arch)),
    #("variant", json.nullable(p.variant, json.string)),
  ])
}

pub fn check_to_json(c: PackCheck) -> Json {
  json.object([
    #("name", json.string(c.name)),
    #("command", json.string(c.command)),
    #("expected_exit", json.int(c.expected_exit)),
  ])
}

pub fn action_to_json(a: PackAction) -> Json {
  json.object([
    #("name", json.string(a.name)),
    #("command", json.string(a.command)),
    #("args", json.array(a.args, json.string)),
    #("description", json.string(a.description)),
  ])
}

pub fn claims_to_json(c: PackClaims) -> Json {
  json.object([
    #("signed", json.bool(c.signed)),
    #("reproducible", json.bool(c.reproducible)),
    #("sbom_included", json.bool(c.sbom_included)),
    #("provenance", json.nullable(c.provenance, json.string)),
  ])
}

/// Encode pack manifest to JSON.
pub fn to_json(m: PackManifest) -> Json {
  json.object([
    #("id", json.string(m.id)),
    #("schema_version", json.string(m.schema_version)),
    #("name", json.string(m.name)),
    #("version", json.string(m.version)),
    #("platforms", json.array(m.platforms, platform_to_json)),
    #("checks", json.array(m.checks, check_to_json)),
    #("actions", json.array(m.actions, action_to_json)),
    #("claims", claims_to_json(m.claims)),
    #("created_at", json.string(m.created_at)),
  ])
}

/// Decoder for parsing a pack manifest from JSON.
pub fn decoder() -> decode.Decoder(PackManifest) {
  use id <- decode.field("id", decode.string)
  use sv <- decode.field("schema_version", decode.string)
  use name <- decode.field("name", decode.string)
  use version <- decode.field("version", decode.string)
  decode.success(PackManifest(
    id: id,
    schema_version: sv,
    name: name,
    version: version,
    platforms: [],
    checks: [],
    actions: [],
    claims: PackClaims(
      signed: False,
      reproducible: False,
      sbom_included: False,
      provenance: None,
    ),
    created_at: "",
  ))
}
