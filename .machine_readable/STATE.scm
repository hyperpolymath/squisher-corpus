;; SPDX-License-Identifier: PMPL-1.0-or-later
;; STATE.scm - Project state tracking for squisher-corpus
;; Media-Type: application/vnd.state+scm

(define-state squisher-corpus
  (metadata
    (version "0.1.0")
    (schema-version "1.0.0")
    (created "2026-02-12")
    (updated "2026-02-13")
    (project "squisher-corpus")
    (repo "hyperpolymath/squisher-corpus"))

  (project-context
    (name "squisher-corpus")
    (tagline "Empirical schema corpus for protocol-squisher pattern mining")
    (tech-stack ("elixir" "oban" "ecto" "sqlite" "gleam")))

  (current-position
    (phase "implementation")
    (overall-completion 30)
    (components
      (("pipeline" . 0)
       ("mining" . 0)
       ("database" . 0)
       ("export" . 0)
       ("composer" . 30)))
    (working-features
      ("composer-contract-types"
       "composer-pipeline-orchestration"
       "composer-bundler")))

  (route-to-mvp
    (milestones
      ((name "Repository Setup")
       (status "done")
       (completion 100)
       (items
         ("Create from rsr-template-repo" . done)
         ("Replace template placeholders" . done)
         ("Update SCM files" . done)))
      ((name "Elixir Application")
       (status "in-progress")
       (completion 0)
       (items
         ("Initialize Mix project" . todo)
         ("Create Ecto migrations" . todo)
         ("Implement pipeline workers" . todo)
         ("Implement pattern mining" . todo)
         ("Write tests" . todo)))
      ((name "Integration")
       (status "not-started")
       (completion 0)
       (items
         ("Integrate with protocol-squisher CLI" . todo)
         ("Export to Hypatia" . todo)
         ("Run on real GitHub data" . todo)))))

  (blockers-and-issues
    (critical ())
    (high ())
    (medium ())
    (low ()))

  (critical-next-actions
    (immediate
      "Implement full JSON decoders for all 8 contract types"
      "Wire real shell execution in runner.gleam (panic-attack, clinician, observatory)")
    (this-week
      "BEAM interop: call Gleam composer from Elixir Observatory"
      "Create Mix project structure for Elixir pipeline workers"
      "Define Ecto schemas and migrations")
    (this-month
      "Implement all 5 Oban pipeline workers"
      "Run corpus collection on GitHub"
      "Generate first empirical dataset"))

  (session-history
    ("2026-02-13: Gleam composer engine — 8 contract types, pipeline, bundler, runner, 22 tests"
     "2026-02-13: Fixed within-package imports (bare paths, not package-prefixed)"
     "2026-02-13: contracts/WIRING.md tracking cross-language schema status")))

;; Helper functions
(define (get-completion-percentage state)
  (current-position 'overall-completion state))

(define (get-blockers state severity)
  (blockers-and-issues severity state))

(define (get-milestone state name)
  (find (lambda (m) (equal? (car m) name))
        (route-to-mvp 'milestones state)))
