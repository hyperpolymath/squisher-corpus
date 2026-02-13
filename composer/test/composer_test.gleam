// SPDX-License-Identifier: PMPL-1.0-or-later

import composer
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn version_test() {
  composer.version()
  |> should.equal("0.1.0")
}

pub fn schema_names_count_test() {
  let names = composer.schema_names()
  names |> should.not_equal([])
}

pub fn check_contracts_test() {
  composer.check_contracts()
  |> should.be_true
}
