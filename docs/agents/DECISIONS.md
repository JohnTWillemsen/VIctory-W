# Decision register — append only

Each decision needs an ID, date, why, options rejected, authorization, evidence and rollback/revisit condition. This is **not** the current-state file.

### D-001 — 2026-11-26 — Start VIctory-W from Marvisak's original source

**Decision:** Use `JohnTWillemsen/VIctory-W` as a separate, clean fork of `Marvisak/VIctory`. Original observed `main` SHA: `63bcca43c6a00a758510398fa43096ce7e4f7df0`. Do not replace the new fork with old experimental integration.

**Why:** Owner wants to contribute broadly useful improvements to the original upstream while keeping reproducible RTX 5090 experimental work separate. The old fork is still useful for ideas and evidence but carries different branch ancestry.

**Alternatives:** Directly fork the experimental fxceless tree or wholesale merge the old fork (rejected as uncontrolled baseline change). Full new compatibility-layer rewrite (rejected as duplicating years of work).

**Evidence/authority:** Owner created the new fork and requested agent governance; live GitHub `main`/upstream SHA inspected (E-001). **No gameplay result implied.**

**Revisit:** Only after explicit owner decision supported by a concrete need.

### D-002 — 2026-11-26 — Adopt evidence-gated multi-agent process

**Decision:** Keep a concise root AGENTS file and one mutable current-state snapshot; separate append-only evidence and decision records, candidate research, a bounded task queue, test protocol, PR template, and a CI guard for document integrity. Agents work in isolated branches and **do not self-merge or update gameplay-status claims without evidence**.

**Why:** Previous handoffs accumulated stale statements. A short entry point plus append-only provenance helps new agents detect contradictions and avoid redoing previously rejected work.

**Owner intent:** User explicitly requested structured, anti-hallucination agent setup. **This decision does not itself authorize merging any runtime code**.

**Revisit:** Adjust after real multi-session use and a reviewed governance PR, not by silently removing audit logs.

### D-003 — 2026-11-26 — Make synthetic restart and conflict regression a required docs CI check

**Decision:** Run [RESTART_TEST_PROTOCOL](RESTART_TEST_PROTOCOL.md) in the existing `agent-docs` workflow. Its test uses temporary local Git clones and a bare remote to check process restarts, SIGKILL recovery, stale claims, competing updates, missing onboarding and moved baseline refs.

**Why:** Static Markdown checks do not exercise durable checkpoints or stale-writer conflicts. The test now fails closed on missing evidence paths and on session-HOME leakage; an intentionally broken shared-HOME fixture failed locally while the corrected script passed.

**Limitations:** This is a deterministic Bash/Git rehearsal, **not** a restarted AI agent, a real GitHub PR concurrency test, protection-ruleset verification, or an RTX 5090 gameplay measurement. Those still require separately authorized operational tests.

**Evidence:** [CI 45867868772](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45867868772), exact head `997152e30e57e0d810fbf4275ebfacf8b3370b73`. Owner requested a controlled restart test; no authorization to merge runtime changes or this draft PR is inferred.

**Revisit:** If the protocol or AI execution model changes, add a focused negative regression. Keep GitHub branch protection and genuine independent AI-agent acceptance as separate gates.
