;; SPDX-License-Identifier: PMPL-1.0-or-later
;; META.scm - Architectural decisions and project meta-information
;; Media-Type: application/meta+scheme

(define-meta squisher-corpus
  (version "1.0.0")

  (architecture-decisions
    ((adr-001 accepted "2026-02-12"
      "Need empirical data on real-world schema patterns to guide protocol-squisher format expansion"
      "Build an Elixir OTP application with Oban job queue to crawl GitHub, analyze schemas, and mine patterns"
      "Provides data-driven insights for transport class optimization. "
      "Requires GitHub API token and protocol-squisher CLI on PATH.")

    (adr-002 accepted "2026-02-12"
      "Need persistent storage for corpus data and analysis results"
      "Use SQLite via ecto_sqlite3 for zero-configuration local storage"
      "Simple deployment, no external database server needed. "
      "Sufficient for corpus sizes up to ~100K schemas.")

    (adr-003 accepted "2026-02-12"
      "Need reliable background job processing for multi-stage pipeline"
      "Use Oban for job queue with 5 pipeline stages"
      "Built-in retry logic, rate limiting, and job dependencies. "
      "SQLite-backed queue matches our storage choice."))

  (development-practices
    (code-style
      "Elixir with standard formatter. "
      "GenServer for stateful components (rate limiter). "
      "Oban workers for pipeline stages.")
    (security
      "GitHub API rate limiting enforced. "
      "No secrets stored in database. "
      "Hypatia neurosymbolic scanning enabled.")
    (testing
      "Unit tests for each pipeline worker. "
      "Property-based tests with StreamData. "
      "Integration tests with known schema fixtures.")
    (versioning
      "Semantic versioning (semver).")
    (documentation
      "README.adoc for overview. "
      "STATE.scm for current state. "
      "ECOSYSTEM.scm for relationships.")
    (branching
      "Main branch protected. "
      "Feature branches for new work."))

  (design-rationale
    (why-elixir
      "OTP supervision trees provide fault tolerance for long-running crawls. "
      "Oban provides reliable job processing with SQLite backend. "
      "GenServer naturally models the rate limiter state machine.")
    (why-sqlite
      "Zero-configuration, single-file database. "
      "Sufficient for corpus analysis workloads. "
      "Easy to backup, share, and inspect.")
    (why-oban
      "Mature job queue with retry semantics. "
      "Native Ecto integration. "
      "Supports job dependencies between pipeline stages.")))
