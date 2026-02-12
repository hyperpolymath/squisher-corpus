;; SPDX-License-Identifier: PMPL-1.0-or-later
;; STATE.scm - Project state tracking for squisher-corpus
;; Media-Type: application/vnd.state+scm

(define-state squisher-corpus
  (metadata
    (version "0.1.0")
    (schema-version "1.0.0")
    (created "2026-02-12")
    (updated "2026-02-12")
    (project "squisher-corpus")
    (repo "hyperpolymath/squisher-corpus"))

  (project-context
    (name "squisher-corpus")
    (tagline "Empirical schema corpus for protocol-squisher pattern mining")
    (tech-stack ("elixir" "oban" "ecto" "sqlite")))

  (current-position
    (phase "implementation")
    (overall-completion 10)
    (components
      (("pipeline" . 0)
       ("mining" . 0)
       ("database" . 0)
       ("export" . 0)))
    (working-features ()))

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
      "Create Mix project structure"
      "Define Ecto schemas and migrations")
    (this-week
      "Implement all 5 pipeline workers"
      "Add pattern mining module")
    (this-month
      "Run corpus collection on GitHub"
      "Generate first empirical dataset"))

  (session-history ()))

;; Helper functions
(define (get-completion-percentage state)
  (current-position 'overall-completion state))

(define (get-blockers state severity)
  (blockers-and-issues severity state))

(define (get-milestone state name)
  (find (lambda (m) (equal? (car m) name))
        (route-to-mvp 'milestones state)))
