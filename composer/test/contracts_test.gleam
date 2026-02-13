// SPDX-License-Identifier: PMPL-1.0-or-later

import contracts/ambient_payload
import contracts/envelope
import contracts/message_intent
import contracts/pack_manifest
import contracts/plan
import contracts/receipt
import contracts/run_bundle
import contracts/weather
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// --- Envelope roundtrip ---

pub fn envelope_new_and_encode_test() {
  let env = envelope.EvidenceEnvelope(
    id: "env-001",
    schema_version: "1.0.0",
    created_at: "2026-02-13T00:00:00Z",
    source: envelope.EnvelopeSource(
      repo: "hyperpolymath/test",
      ref: Some("main"),
      tool: envelope.SourceTool(name: "panic-attack", version: "0.5.0"),
    ),
    findings: [
      envelope.Finding(
        id: "f-1",
        severity: envelope.High,
        title: "Weak entropy",
        description: "Insufficient randomness source",
        location: Some("src/main.rs:42"),
      ),
    ],
    artifacts: [],
  )
  let json_str = envelope.to_json(env) |> json.to_string
  json_str |> string.contains("env-001") |> should.be_true
  json_str |> string.contains("panic-attack") |> should.be_true
  json_str |> string.contains("high") |> should.be_true
}

// --- Plan roundtrip ---

pub fn plan_new_and_encode_test() {
  let p = plan.ProcedurePlan(
    id: "plan-001",
    schema_version: "1.0.0",
    name: "Corpus Scan",
    description: "Full corpus analysis",
    steps: [
      plan.PlanStep(
        id: "s1",
        name: "scan",
        action: plan.ShellCommand("panic-attack", ["assail", "."]),
        risk: plan.Low,
        reversibility: plan.FullyReversible,
        depends_on: [],
      ),
    ],
    overall_risk: plan.Low,
    dry_run: False,
    created_at: "2026-02-13T00:00:00Z",
  )
  let json_str = plan.to_json(p) |> json.to_string
  json_str |> string.contains("plan-001") |> should.be_true
  json_str |> string.contains("shell_command") |> should.be_true
  json_str |> string.contains("fully_reversible") |> should.be_true
}

// --- Receipt roundtrip ---

pub fn receipt_new_and_encode_test() {
  let r = receipt.Receipt(
    id: "rcpt-001",
    schema_version: "1.0.0",
    plan_id: "plan-001",
    status: receipt.Succeeded,
    step_results: [
      receipt.StepResult(
        step_id: "s1",
        status: receipt.StepSucceeded,
        output: Some("ok"),
        error: None,
        duration_ms: 150,
        undo: None,
      ),
    ],
    started_at: "2026-02-13T00:00:00Z",
    completed_at: "2026-02-13T00:00:01Z",
  )
  let json_str = receipt.to_json(r) |> json.to_string
  json_str |> string.contains("rcpt-001") |> should.be_true
  json_str |> string.contains("succeeded") |> should.be_true
}

// --- Weather roundtrip ---

pub fn weather_new_and_encode_test() {
  let w = weather.SystemWeather(
    id: "wx-001",
    schema_version: "1.0.0",
    state: weather.Clear,
    summary: "All systems nominal",
    trends: [
      weather.Trend(
        category: weather.Performance,
        direction: weather.Stable,
        metric: "throughput",
        value: 95.2,
      ),
    ],
    observed_at: "2026-02-13T00:00:00Z",
  )
  let json_str = weather.to_json(w) |> json.to_string
  json_str |> string.contains("clear") |> should.be_true
  json_str |> string.contains("performance") |> should.be_true
  json_str |> string.contains("95.2") |> should.be_true
}

// --- MessageIntent roundtrip ---

pub fn message_intent_new_and_encode_test() {
  let mi = message_intent.MessageIntent(
    id: "mi-001",
    schema_version: "1.0.0",
    action: "notify",
    audience: message_intent.Bot,
    content: message_intent.IntentContent(
      mime_type: "application/json",
      body: "{\"msg\":\"hello\"}",
      encoding: None,
    ),
    routing: message_intent.RoutingTarget(
      service: "gitbot-fleet",
      queue: Some("high-priority"),
      priority: 1,
    ),
    correlation_id: Some("corr-abc"),
    created_at: "2026-02-13T00:00:00Z",
  )
  let json_str = message_intent.to_json(mi) |> json.to_string
  json_str |> string.contains("mi-001") |> should.be_true
  json_str |> string.contains("bot") |> should.be_true
  json_str |> string.contains("gitbot-fleet") |> should.be_true
}

// --- PackManifest roundtrip ---

pub fn pack_manifest_new_and_encode_test() {
  let pm = pack_manifest.PackManifest(
    id: "pack-001",
    schema_version: "1.0.0",
    name: "corpus-tools",
    version: "1.0.0",
    platforms: [
      pack_manifest.PackPlatform(os: "linux", arch: "x86_64", variant: None),
    ],
    checks: [
      pack_manifest.PackCheck(name: "version", command: "panic-attack --version", expected_exit: 0),
    ],
    actions: [],
    claims: pack_manifest.PackClaims(
      signed: True,
      reproducible: True,
      sbom_included: True,
      provenance: Some("github-actions"),
    ),
    created_at: "2026-02-13T00:00:00Z",
  )
  let json_str = pack_manifest.to_json(pm) |> json.to_string
  json_str |> string.contains("pack-001") |> should.be_true
  json_str |> string.contains("corpus-tools") |> should.be_true
  json_str |> string.contains("github-actions") |> should.be_true
}

// --- AmbientPayload roundtrip ---

pub fn ambient_payload_new_and_encode_test() {
  let ap = ambient_payload.AmbientPayload(
    id: "amb-001",
    schema_version: "1.0.0",
    state: ambient_payload.Active,
    indicators: [
      ambient_payload.Indicator(
        name: "cpu",
        value: "42%",
        unit: Some("percent"),
        threshold: Some(80.0),
      ),
    ],
    badges: [
      ambient_payload.Badge(label: "healthy", color: "green", icon: None),
    ],
    popovers: [],
    observed_at: "2026-02-13T00:00:00Z",
  )
  let json_str = ambient_payload.to_json(ap) |> json.to_string
  json_str |> string.contains("amb-001") |> should.be_true
  json_str |> string.contains("active") |> should.be_true
  json_str |> string.contains("cpu") |> should.be_true
}

// --- RunBundle roundtrip ---

pub fn run_bundle_new_and_encode_test() {
  let rb = run_bundle.RunBundle(
    id: "rb-001",
    schema_version: "1.0.0",
    pipeline_id: "pipe-001",
    bundle_type: run_bundle.Full,
    layout: run_bundle.BundleLayout(
      root: "/tmp/bundles",
      receipts_dir: "receipts",
      artifacts_dir: "artifacts",
      logs_dir: "logs",
    ),
    contents: [
      run_bundle.BundleContent(
        path: "receipts/step-0.json",
        media_type: "application/json",
        size_bytes: 256,
      ),
    ],
    retention: run_bundle.RetentionPolicy(
      keep_days: 90,
      compress: True,
      archive_to: Some("s3://archive"),
    ),
    created_at: "2026-02-13T00:00:00Z",
  )
  let json_str = run_bundle.to_json(rb) |> json.to_string
  json_str |> string.contains("rb-001") |> should.be_true
  json_str |> string.contains("full") |> should.be_true
  json_str |> string.contains("s3://archive") |> should.be_true
}
