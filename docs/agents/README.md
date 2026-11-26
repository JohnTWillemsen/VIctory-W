# Agent operating system — navigation index

**Read [AGENTS.md](../../AGENTS.md) first.** This directory makes the project reproducible between sessions; it is not a replacement for the live repository or CI. Avoid duplicating the same fact in several files.

| File | One job | Update policy |
| --- | --- | --- |
| [CURRENT_STATE.md](CURRENT_STATE.md) | **Only mutable present-tense handoff:** exact verified refs, task in progress, blockers, next actions | Update at the end of a substantive task; stamp date, author/context, source URLs |
| [ROADMAP.md](ROADMAP.md) | Stable priority order, acceptance gates, scope | Update when priorities change; add a decision record |
| [TASK_QUEUE.md](TASK_QUEUE.md) | Bounded work IDs, owners, allowed edits and branch coordination | Update at claim, PR and closure; no pretend background progress |
| [WORKFLOW.md](WORKFLOW.md) | Orchestrator/worker/validator boundaries, branch + PR process | Version with an explanatory PR |
| [RESEARCH_PROTOCOL.md](RESEARCH_PROTOCOL.md) | How to review issues, compare forks, prevent duplicate or imaginary fixes | Version with explanatory PR |
| [TESTING.md](TESTING.md) | Source checks, evidence tiers and safe Windows/5090 testing | Update with validated test procedures |
| [EVIDENCE_LOG.md](EVIDENCE_LOG.md) | **Append-only** source, CI, synthetic and device test observations | Append a dated entry; correct mistakes with a linked correction, not deletion |
| [DECISIONS.md](DECISIONS.md) | **Append-only** rationale for strategy, risky changes, promotions and rejections | Append an ID and relevant evidence |
| [UPSTREAM_TRACKER.md](UPSTREAM_TRACKER.md) | Candidates and upstream PR statuses, with explicit freshness limits | Reverify before each implementation |
| [ARCHITECTURE_INDEX.md](ARCHITECTURE_INDEX.md) | Directory-to-subsystem source map, no copy of architecture | Update if crate layout changes |
| [LEGACY_CONTEXT.md](LEGACY_CONTEXT.md) | Historical pointers to previous fork; **not imported into this fork** | Historical, link-only; never promote on memory |
| [EXPERIMENT_TEMPLATE.md](EXPERIMENT_TEMPLATE.md) | One-page reproducible hypothesis and A/B experiment template | Copy to PR description or private test notes |
| [NEW_SESSION_PROMPT.md](NEW_SESSION_PROMPT.md) | Paste-ready handoff for a new agent | Keep concise, in sync with AGENTS |
| [RESTART_TEST_PROTOCOL.md](RESTART_TEST_PROTOCOL.md) | Reproducible cold-start, interruption and conflict simulations with explicit AI limitations | Update when CI rehearsal scenarios change |

**Source-of-truth order:** current GitHub code and exact SHA → completed linked CI/test results → independently recorded local hardware evidence → dated handoff → upstream author reports → hypotheses. A lower tier cannot override a higher tier without investigation.

**Refresh sequence:** read required docs → verify live HEAD, open PRs and CI → inspect actual source and tests → check task collisions → do bounded work on a dedicated branch → report evidence/blocked steps in the PR → orchestrator reconciles shared CURRENT_STATE/TASK_QUEUE and append-only records. If GitHub or required test inputs are inaccessible, label the blocked portion `UNKNOWN` or `NOT_RUN`, do useful source-only work, and stop short of acceptance claims.

Do not put screenshots, copyrighted artifacts, title-derived dumps, private logs or credentials in agent documents.
