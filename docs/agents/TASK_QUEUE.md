# Bounded task queue (orchestrator-owned)

Tasks are small, single-branch assignments; a task's existence is **not** proof it was implemented. `CLAIMED` means a worker reserved its branch, not a background agent is running. No agent may promise work continues after its session ends without an actual scheduling tool.

| Task | Status | Worker / branch | Allowed scope and acceptance gate |
| --- | --- | --- | --- |
| VW-001 · Agent governance scaffolding | CLAIMED in current session | Orchestrator · `docs/agent-continuity-system-20261126` | Documentation, templates and document integrity workflow only. No Rust behavior; read back tree/diff; pass docs check and exact-head CI if available. Owner approves merge. |
| VW-002 · Verify baseline CI | READY after VW-001 | Unassigned | Inspect exact new-fork `main` and PR CI; record toolchain, commands, successes/failures, skipped tests, evidence links. No game assets. |
| VW-003 · Candidate de-duplication | BACKLOG | Unassigned | Inspect a **single** upstream candidate, compare to actual VIctory-W code and tests, document no-change or minimal patch plan. Research only until new scope is approved. |
| VW-004 · Native RTX 5090 baseline | BLOCKED on owner hardware execution | Owner/tester | Use licensed game data locally; get exact executable identity and visuals/frametimes or device loss; no game content in Git. |

**Claim protocol:** Update task with agent/session identifier, base SHA, branch, expected files, permitted test operations and stop condition before writing. Only one implementation worker per branch. On completion set `PR OPEN`, `DONE` or `BLOCKED` with link and next step; update CURRENT_STATE and EVIDENCE_LOG only for verified events. Re-check live branch/PR state first because this table is only a dated snapshot.
