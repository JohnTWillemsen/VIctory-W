# Agent documentation — authoritative navigation

For the NVIDIA-based VIctory-W, **read [AGENTS.md](../../AGENTS.md) and [HANDOFF.md](HANDOFF.md) first.** Do not start from the 2026-11-26 Marvisak experiments or historical draft PRs.

| Source | What it means | Updating it |
| --- | --- | --- |
| [LOCAL_WORKSPACE.md](LOCAL_WORKSPACE.md) | Safe Windows clone/bootstrap, new source and report roots, and old checkout/game isolation | Verify locally; update when owner changes directory agreement |
| [HANDOFF.md](HANDOFF.md) | Canonical short *dated* NVIDIA source/CI/owner gameplay/workspace handoff | Update whenever the accepted foundation, playability evidence or owner test procedure changes |
| [CURRENT_STATE.md](CURRENT_STATE.md) | Short current state, exact linked runs/commit as of last checkpoint | Refresh at each substantial milestone; **always recheck live GitHub** |
| [LATEST_CHECKPOINT.md](LATEST_CHECKPOINT.md) | Quick last milestone plus immediate next step | Refresh with accepted evidence, no speculative progress |
| [NEW_SESSION_PROMPT.md](NEW_SESSION_PROMPT.md) | Small paste-ready new ChatGPT session bootstrap, no hard-coded SHA | Change only when rules/goal change |
| [TASK_QUEUE.md](TASK_QUEUE.md) | Small active priorities and statuses; previous 112 KB queue preserved in Git history | Never use as a lock; inspect live PRs |
| [EVIDENCE_LOG.md](EVIDENCE_LOG.md) | Detailed **append-only** E-series observations | Only append; corrections get a new row |
| [DECISIONS.md](DECISIONS.md) | Detailed **append-only** D-series rationale and authorizations | Only append |
| [WORKFLOW.md](WORKFLOW.md) | Roles and source-controlled branch/PR gates | Change with rationale and source review |
| [RESEARCH_PROTOCOL.md](RESEARCH_PROTOCOL.md) | Read/compare source and upstream proposals, distinguish reports from tests | Update for materially changed procedures |
| [TESTING.md](TESTING.md) | Background source/synthetic/hardware acceptance detail | NVIDIA live protocol is [E127](../research/E127-TESTING-AND-UPLOAD-PROTOCOL.md) |
| [RESTART_TEST_PROTOCOL.md](RESTART_TEST_PROTOCOL.md) | What the currently installed cold-clone CI actually tests | Update alongside `scripts/check-continuity.py` |
| [NVIDIA_SOURCE_PIN.md](../migration/NVIDIA_SOURCE_PIN.md) | Upstream exact v8 provenance, preserved old-source archive and licensing | Pin new upstream revisions explicitly, never by "latest" |
| [E127 testing / upload protocol](../research/E127-TESTING-AND-UPLOAD-PROTOCOL.md) | One owner-consented supervised run and privacy-safe ZIP/recovery | Keep script and synthetic test aligned |

**Authoritative evidence order:** live GitHub code/branch/PR head > completed exact-head CI/results > anonymized real RTX5090 owner observations > dated snapshot > third-party maintainer reports > hypotheses.

**Anti-staleness rule:** A fixed SHA in a dated document is a *historical checkpoint*, not a requirement that the branch remain frozen. Always fetch current main, PRs and CI first and flag changed or contradictory facts. Old source/task details are retained in Git history and append-only logs; never silently revive old code because a historical paragraph says "current."

**Offline check:** `python scripts/check-continuity.py --smoke-clone` checks required docs, concise size limits, NVIDIA source pin, evidence sequence, owner report guardrails, then clones the committed checkout into a disposable Git directory and fails closed on a missing canonical file. It is a **process test**, not an AI or gameplay test.

**Privacy:** No title data, raw logs, screenshots, private paths, shaders, crash dumps or credentials in these docs or the PUBLIC repository.
