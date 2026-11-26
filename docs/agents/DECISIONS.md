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
