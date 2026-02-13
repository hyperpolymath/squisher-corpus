// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

/// System weather contract — ambient health/state signals for the corpus pipeline.

import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

/// Overall weather state.
pub type WeatherState {
  Clear
  Cloudy
  Stormy
  Degraded
  Unknown
}

/// Category of the weather signal.
pub type WeatherCategory {
  Performance
  Availability
  Security
  Compliance
  Resource
}

/// Direction of a trend.
pub type TrendDirection {
  Improving
  Stable
  Declining
}

/// A trend observation.
pub type Trend {
  Trend(
    category: WeatherCategory,
    direction: TrendDirection,
    metric: String,
    value: Float,
  )
}

/// Top-level system weather.
pub type SystemWeather {
  SystemWeather(
    id: String,
    schema_version: String,
    state: WeatherState,
    summary: String,
    trends: List(Trend),
    observed_at: String,
  )
}

/// Create a default system weather.
pub fn new() -> SystemWeather {
  SystemWeather(
    id: "",
    schema_version: "1.0.0",
    state: Unknown,
    summary: "",
    trends: [],
    observed_at: "",
  )
}

pub fn state_to_string(s: WeatherState) -> String {
  case s {
    Clear -> "clear"
    Cloudy -> "cloudy"
    Stormy -> "stormy"
    Degraded -> "degraded"
    Unknown -> "unknown"
  }
}

pub fn state_from_string(s: String) -> Result(WeatherState, Nil) {
  case s {
    "clear" -> Ok(Clear)
    "cloudy" -> Ok(Cloudy)
    "stormy" -> Ok(Stormy)
    "degraded" -> Ok(Degraded)
    "unknown" -> Ok(Unknown)
    _ -> Error(Nil)
  }
}

pub fn category_to_string(c: WeatherCategory) -> String {
  case c {
    Performance -> "performance"
    Availability -> "availability"
    Security -> "security"
    Compliance -> "compliance"
    Resource -> "resource"
  }
}

pub fn direction_to_string(d: TrendDirection) -> String {
  case d {
    Improving -> "improving"
    Stable -> "stable"
    Declining -> "declining"
  }
}

pub fn trend_to_json(t: Trend) -> Json {
  json.object([
    #("category", json.string(category_to_string(t.category))),
    #("direction", json.string(direction_to_string(t.direction))),
    #("metric", json.string(t.metric)),
    #("value", json.float(t.value)),
  ])
}

/// Encode system weather to JSON.
pub fn to_json(w: SystemWeather) -> Json {
  json.object([
    #("id", json.string(w.id)),
    #("schema_version", json.string(w.schema_version)),
    #("state", json.string(state_to_string(w.state))),
    #("summary", json.string(w.summary)),
    #("trends", json.array(w.trends, trend_to_json)),
    #("observed_at", json.string(w.observed_at)),
  ])
}

/// Decoder for parsing system weather from JSON.
pub fn decoder() -> decode.Decoder(SystemWeather) {
  use id <- decode.field("id", decode.string)
  use sv <- decode.field("schema_version", decode.string)
  use state_str <- decode.field("state", decode.string)
  let state = case state_from_string(state_str) {
    Ok(s) -> s
    Error(_) -> Unknown
  }
  decode.success(SystemWeather(
    id: id,
    schema_version: sv,
    state: state,
    summary: "",
    trends: [],
    observed_at: "",
  ))
}
