# Multi-agent workflow and change-control protocol

One conversation is not the source of truth. GitHub code, commits, CI, and the dated [CURRENT_STATE](CURRENT_STATE.md) are. A role describes **authorization and evidence responsibilities**, not guaranteed access to hardware or tools.

## Roles and handoff

- **Owner / human:** selects priorities, approves risky defaults, decides if work is promoted to `main` or submitted upstream, supplies local hardware test results; only the owner can authorize game-file access and gameplay claims.
- **Orchestrator (one per workstream):** verifies current live refs, assigns a **bounded** task and starting SHA, prevents agents editing the same branch, collects outcomes, updates CURRENT_STATE and roadmap. Do not assign a task without source pointers and a test gate.
- **Research worker:** read-only inspection of GitHub code/issues/tests/commit ancestry. Output exact URLs/SHAs, duplicate search and hypothesis; **no writes**.
- **Implementation worker:** only one issue/patch on a named new branch starting at an exact verified SHA. Read relevant files, add a failing regression, change minimum code, commit and open draft PR. Cannot self-merge.
- **Review/validation worker:** inspect actual diff and latest head, rerun reproducible checks, identify regressions, check citations/attribution, confirm no game material. May recommend changes; not permitted to claim unobserved gameplay.
- **Hardware tester:** executes on the specified physical GPU, documents driver/build/hash/config/scene, keeps files and captures private; provides only sanitized observations.

A single agent may do multiple roles when no other workers are available, but must **say so**; do not pretend independent review happened.

## Session bootstrap (required even after a prior chat says 'continue')

1. Read AGENTS and linked docs; determine project and task.
2. Query GitHub live: repo/default SHA, related open PRs, relevant branch SHA, upstream SHA and CI. Check whether someone already implemented the proposed change.
3. Restate the scope and acceptance gate. If a requested ref vanished or moved, **do not write** until reverified; log the discrepancy.
4. Check other **open PRs/branch heads** for the same task ID and touched paths; TASK_QUEUE is a dated hint, **not a lock**. Create a unique branch from the exact verified base. No direct `main` writes. For longer tasks, reserve ownership with a small task-scoped first commit and draft PR before substantive implementation.
5. Read actual code paths + tests. Use existing architecture and policy, preserve toolchain pin.
6. Make the smallest coherent change with explicit regression tests. Run the checks in TESTING where available.
7. Open **draft PR** and report checks with linked run IDs. Never call a PR verified merely because GitHub said mergeable. Publish an accurate rollback and remaining hardware gate.
8. Record full handoff, evidence and changed paths in the PR. The orchestrator reconciles shared CURRENT_STATE/TASK_QUEUE and append-only EVIDENCE_LOG/DECISIONS using live PR state. When operating alone, propose shared-doc updates in the same PR and recheck conflicts before merging; maintain UPSTREAM_TRACKER for researched candidates.

## Parallel-task coordination

Each implementation task needs a stable ID (e.g. `VW-001`), **specific paths**, owner/worker, base SHA, branch name, hypothesis, allowed edits, expected tests and stop condition. Before implementing, query **live open PRs/branches** for overlapping task IDs and files; a queue entry marked CLAIMED from an ended session does **not** reserve anything indefinitely. The active PR and branch SHA establish whether a workstream exists. Use a unique branch and focused draft PR; never edit another worker's branch or let two workers independently change CURRENT_STATE/TASK_QUEUE. Research can proceed in parallel, but no hidden mass-merges.

When source moves, rebase only after reading the new upstream change and reviewing conflicts. Never force-push an owner's/reference branch. If a PR becomes stale, explain the revalidation plan.

## Promotion rules

A candidate may be merged to `main` **only** with owner approval, source review, passing exact-head checks required for that scope, no unexpected assets or behavior, clear risk/rollback and explicit notes about unperformed native tests. Graphics/runtime behavior cannot be described as confirmed on RTX 5090 until tested there. An upstream Marvisak PR is a **separate, explicitly requested action**, not an automatic consequence of an internal green build.

## Failure, conflicts, and unfinished work

If tools, GitHub, assets, GPU or permissions are unavailable: mark affected step `BLOCKED / UNKNOWN / NOT_RUN`, preserve reproducible source findings, and finish only tasks actually permitted. If there is a security/asset-policy violation: stop and alert the owner; do not attempt silent history rewriting. Do not erase failed observations or overwrite someone else's decision.
