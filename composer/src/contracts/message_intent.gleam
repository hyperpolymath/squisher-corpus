// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

/// Message intent contract — describes the purpose and routing of a message
/// within the corpus pipeline.

import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

/// Target audience for the message.
pub type IntentAudience {
  Human
  Bot
  System
  Broadcast
}

/// Content payload of the intent.
pub type IntentContent {
  IntentContent(
    mime_type: String,
    body: String,
    encoding: Option(String),
  )
}

/// Routing target for the message.
pub type RoutingTarget {
  RoutingTarget(
    service: String,
    queue: Option(String),
    priority: Int,
  )
}

/// Top-level message intent.
pub type MessageIntent {
  MessageIntent(
    id: String,
    schema_version: String,
    action: String,
    audience: IntentAudience,
    content: IntentContent,
    routing: RoutingTarget,
    correlation_id: Option(String),
    created_at: String,
  )
}

/// Create a default message intent.
pub fn new() -> MessageIntent {
  MessageIntent(
    id: "",
    schema_version: "1.0.0",
    action: "",
    audience: System,
    content: IntentContent(mime_type: "application/json", body: "", encoding: None),
    routing: RoutingTarget(service: "", queue: None, priority: 0),
    correlation_id: None,
    created_at: "",
  )
}

pub fn audience_to_string(a: IntentAudience) -> String {
  case a {
    Human -> "human"
    Bot -> "bot"
    System -> "system"
    Broadcast -> "broadcast"
  }
}

pub fn audience_from_string(s: String) -> Result(IntentAudience, Nil) {
  case s {
    "human" -> Ok(Human)
    "bot" -> Ok(Bot)
    "system" -> Ok(System)
    "broadcast" -> Ok(Broadcast)
    _ -> Error(Nil)
  }
}

pub fn content_to_json(c: IntentContent) -> Json {
  json.object([
    #("mime_type", json.string(c.mime_type)),
    #("body", json.string(c.body)),
    #("encoding", json.nullable(c.encoding, json.string)),
  ])
}

pub fn routing_to_json(r: RoutingTarget) -> Json {
  json.object([
    #("service", json.string(r.service)),
    #("queue", json.nullable(r.queue, json.string)),
    #("priority", json.int(r.priority)),
  ])
}

/// Encode message intent to JSON.
pub fn to_json(m: MessageIntent) -> Json {
  json.object([
    #("id", json.string(m.id)),
    #("schema_version", json.string(m.schema_version)),
    #("action", json.string(m.action)),
    #("audience", json.string(audience_to_string(m.audience))),
    #("content", content_to_json(m.content)),
    #("routing", routing_to_json(m.routing)),
    #("correlation_id", json.nullable(m.correlation_id, json.string)),
    #("created_at", json.string(m.created_at)),
  ])
}

/// Decoder for parsing a message intent from JSON.
pub fn decoder() -> decode.Decoder(MessageIntent) {
  use id <- decode.field("id", decode.string)
  use sv <- decode.field("schema_version", decode.string)
  use action <- decode.field("action", decode.string)
  decode.success(MessageIntent(
    id: id,
    schema_version: sv,
    action: action,
    audience: System,
    content: IntentContent(mime_type: "application/json", body: "", encoding: None),
    routing: RoutingTarget(service: "", queue: None, priority: 0),
    correlation_id: None,
    created_at: "",
  ))
}
