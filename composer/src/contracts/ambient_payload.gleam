// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

/// Ambient payload contract — passive environmental signals and UI hints.

import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

/// Current ambient state.
pub type AmbientState {
  Idle
  Active
  Warning
  Alert
  Offline
}

/// An indicator within the payload.
pub type Indicator {
  Indicator(
    name: String,
    value: String,
    unit: Option(String),
    threshold: Option(Float),
  )
}

/// A badge for UI display.
pub type Badge {
  Badge(
    label: String,
    color: String,
    icon: Option(String),
  )
}

/// A popover hint for interactive display.
pub type Popover {
  Popover(
    title: String,
    body: String,
    severity: String,
  )
}

/// Top-level ambient payload.
pub type AmbientPayload {
  AmbientPayload(
    id: String,
    schema_version: String,
    state: AmbientState,
    indicators: List(Indicator),
    badges: List(Badge),
    popovers: List(Popover),
    observed_at: String,
  )
}

/// Create a default ambient payload.
pub fn new() -> AmbientPayload {
  AmbientPayload(
    id: "",
    schema_version: "1.0.0",
    state: Idle,
    indicators: [],
    badges: [],
    popovers: [],
    observed_at: "",
  )
}

pub fn state_to_string(s: AmbientState) -> String {
  case s {
    Idle -> "idle"
    Active -> "active"
    Warning -> "warning"
    Alert -> "alert"
    Offline -> "offline"
  }
}

pub fn state_from_string(s: String) -> Result(AmbientState, Nil) {
  case s {
    "idle" -> Ok(Idle)
    "active" -> Ok(Active)
    "warning" -> Ok(Warning)
    "alert" -> Ok(Alert)
    "offline" -> Ok(Offline)
    _ -> Error(Nil)
  }
}

pub fn indicator_to_json(i: Indicator) -> Json {
  json.object([
    #("name", json.string(i.name)),
    #("value", json.string(i.value)),
    #("unit", json.nullable(i.unit, json.string)),
    #("threshold", json.nullable(i.threshold, json.float)),
  ])
}

pub fn badge_to_json(b: Badge) -> Json {
  json.object([
    #("label", json.string(b.label)),
    #("color", json.string(b.color)),
    #("icon", json.nullable(b.icon, json.string)),
  ])
}

pub fn popover_to_json(p: Popover) -> Json {
  json.object([
    #("title", json.string(p.title)),
    #("body", json.string(p.body)),
    #("severity", json.string(p.severity)),
  ])
}

/// Encode ambient payload to JSON.
pub fn to_json(a: AmbientPayload) -> Json {
  json.object([
    #("id", json.string(a.id)),
    #("schema_version", json.string(a.schema_version)),
    #("state", json.string(state_to_string(a.state))),
    #("indicators", json.array(a.indicators, indicator_to_json)),
    #("badges", json.array(a.badges, badge_to_json)),
    #("popovers", json.array(a.popovers, popover_to_json)),
    #("observed_at", json.string(a.observed_at)),
  ])
}

/// Decoder for parsing an ambient payload from JSON.
pub fn decoder() -> decode.Decoder(AmbientPayload) {
  use id <- decode.field("id", decode.string)
  use sv <- decode.field("schema_version", decode.string)
  use state_str <- decode.field("state", decode.string)
  let state = case state_from_string(state_str) {
    Ok(s) -> s
    Error(_) -> Idle
  }
  decode.success(AmbientPayload(
    id: id,
    schema_version: sv,
    state: state,
    indicators: [],
    badges: [],
    popovers: [],
    observed_at: "",
  ))
}
