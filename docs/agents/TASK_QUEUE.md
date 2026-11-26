# Bounded task queue (orchestrator-owned)

Tasks are small, single-branch assignments; a task's existence is **not** proof it was implemented. A recorded `CLAIMED` is a **dated intent, not an exclusive lock or evidence that an agent is still running**. Check live open PRs, branches and touched paths before claiming anything. If two agents seem to own the same task or file, stop and coordinate; never overwrite either branch. No agent may promise work continues after its session ends without an actual scheduling tool.

| Task | Status | Worker / branch | Allowed scope and acceptance gate |
| --- | --- | --- | --- |
| VW-001 · Agent governance scaffolding | PR OPEN · CI_PASS on initial head | [Draft PR #1](https://github.com/JohnTWillemsen/VIctory-W/pull/1) · `docs/agent-continuity-system-20261126` | Documentation/agent rules only; CI succeeded at `3f366977d2f96ee898abaa2eb91615794c44c84c` ([Windows CI](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45849390341), [docs integrity](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45849390190)). **Re-run and verify on every later head**; owner approves merge. |
| VW-002 · Verify baseline CI | READY after VW-001 | Unassigned | Inspect exact new-fork `main` and PR CI; record toolchain, commands, successes/failures, skipped tests, evidence links. No game assets. |
| VW-003 · Candidate de-duplication | BACKLOG | Unassigned | Inspect a **single** upstream candidate, compare to actual VIctory-W code and tests, document no-change or minimal patch plan. Research only until new scope is approved. |
| VW-004 · Native RTX 5090 baseline | BLOCKED on owner hardware execution | Owner/tester | Use licensed game data locally; get exact executable identity and visuals/frametimes or device loss; no game content in Git. |

**Claim protocol:** First inspect **live open PRs/branch refs**. Reserve longer tasks with a unique branch, task-ID first commit and draft PR; use its URL/head SHA as the active claim. Workers put updates in their own PR body; the orchestrator later reconciles this index and CURRENT_STATE (only verified evidence goes in EVIDENCE_LOG). Expired sessions never keep a task locked. After merge, mark `DONE` with an exact merge SHA and check results; if blocked, explain why. Re-check live PR state because this table is a dated snapshot.
