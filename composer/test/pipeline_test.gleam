// SPDX-License-Identifier: PMPL-1.0-or-later

import gleam/list
import gleam/option.{None}
import gleeunit
import gleeunit/should
import pipeline
import step_types.{
  Apply, Custom, GenerateWeather, Ingest, Plan, Scan, Skipped,
}

pub fn main() {
  gleeunit.main()
}

pub fn pipeline_create_test() {
  let p = pipeline.create(
    id: "test-pipe",
    name: "Test Pipeline",
    steps: [Scan("device-a"), GenerateWeather],
  )
  p.id |> should.equal("test-pipe")
  p.name |> should.equal("Test Pipeline")
  p.dry_run |> should.be_false
}

pub fn step_ordering_test() {
  let steps = [
    Scan("a"),
    Plan("a", "conservative"),
    Apply("/tmp/plan.json"),
    Ingest("/tmp/envelope.json"),
    GenerateWeather,
  ]
  let p = pipeline.create(id: "ord-test", name: "Ordering", steps: steps)
  list.length(p.steps) |> should.equal(5)
}

pub fn dry_run_skips_all_test() {
  let p = pipeline.Pipeline(
    id: "dry-test",
    name: "Dry Run",
    steps: [Scan("dev1"), GenerateWeather, Custom("echo", ["hello"])],
    dry_run: True,
  )
  let result = pipeline.execute(p)
  result.pipeline_id |> should.equal("dry-test")
  list.all(result.outcomes, fn(o) {
    case o {
      Skipped(_) -> True
      _ -> False
    }
  })
  |> should.be_true
  list.length(result.outcomes) |> should.equal(3)
}

pub fn dry_run_helper_test() {
  let p = pipeline.create(
    id: "dry2",
    name: "Dry Helper",
    steps: [Scan("x"), Ingest("/tmp/e.json")],
  )
  let result = pipeline.dry_run(p)
  list.all(result.outcomes, fn(o) {
    case o {
      Skipped(_) -> True
      _ -> False
    }
  })
  |> should.be_true
}

pub fn rollback_empty_test() {
  let result = pipeline.PipelineResult(
    pipeline_id: "rb-test",
    outcomes: [],
    run_bundle: None,
  )
  let rolled = pipeline.rollback(result)
  rolled.outcomes |> should.equal([])
  rolled.run_bundle |> should.equal(None)
}

pub fn step_label_test() {
  step_types.step_label(Scan("foo"))
  |> should.equal("scan(foo)")

  step_types.step_label(Plan("dev", "aggressive"))
  |> should.equal("plan(dev, aggressive)")

  step_types.step_label(GenerateWeather)
  |> should.equal("generate_weather")

  step_types.step_label(Custom("ls", ["-la"]))
  |> should.equal("custom(ls)")
}
