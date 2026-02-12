;; SPDX-License-Identifier: PMPL-1.0-or-later
;; ECOSYSTEM.scm - Ecosystem relationships for squisher-corpus
;; Media-Type: application/vnd.ecosystem+scm

(ecosystem
  (version "1.0.0")
  (name "squisher-corpus")
  (type "application")
  (purpose "Empirical schema corpus collection and pattern mining for protocol-squisher")

  (position-in-ecosystem
    "Data pipeline feeding protocol-squisher's learning engine. "
    "Crawls GitHub for real-world schemas, analyzes them, and mines patterns "
    "that inform format expansion and transport class optimization.")

  (related-projects
    (dependency "protocol-squisher" "Schema analysis via corpus-analyze CLI subcommand")
    (consumer "hypatia" "Receives Logtalk facts for neurosymbolic reasoning")
    (sibling-standard "rsr-template-repo" "Template for repository structure")
    (integration "gitbot-fleet" "Quality enforcement and automated fixes")
    (integration "verisimdb-data" "Vulnerability pattern cross-reference"))

  (what-this-is
    "An Elixir OTP application that builds an empirical corpus of schema files "
    "from GitHub, runs protocol-squisher analysis on each, stores results in "
    "SQLite, and mines cross-schema patterns for transport class optimization.")

  (what-this-is-not
    "Not a schema registry or validator. "
    "Not a runtime dependency of protocol-squisher. "
    "A research/data-collection tool that feeds the learning pipeline."))
