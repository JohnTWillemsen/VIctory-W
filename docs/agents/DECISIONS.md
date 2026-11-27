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

### D-004 — 2026-11-26 — Persist verified RTX 5090 progress and future-session bootstrap in GitHub

**Decision / owner authorization:** The owner explicitly requested that meaningful testing and research milestones be committed to GitHub so a new conversation can resume reliably, using a better repository-led prompt if helpful. Keep `CURRENT_STATE`, `TASK_QUEUE`, append-only `EVIDENCE_LOG`, candidate tracker and `NEW_SESSION_PROMPT` updated at substantive milestones; put experiment-specific details into their own draft PR. Maintain the verified main baseline and clear owner-controlled merge approvals.

**Why:** Chats can end without sharing hidden context. Durable, dated, exact-SHA evidence and a branch-aware entry prompt prevent repeating tests or confusing successful unit tests with visual correctness. PR #1 contains these documents but **is not merged into main**, so fresh sessions must first read the docs branch, then verify live PRs and current code.

**Alternatives rejected:** Treat chat memory as the source of truth, write raw PowerShell/title logs to Git, copy entire research history into root README, or auto-merge experimental NVIDIA fixes after a green synthetic test.

**Evidence:** E-011 through E-014, including a reproducible baseline failure and 16/16 host tests on [upstream #3300](https://github.com/Marvisak/VIctory/pull/3300); draft governance [PR #1](https://github.com/JohnTWillemsen/VIctory-W/pull/1) and test [PR #3](https://github.com/JohnTWillemsen/VIctory-W/pull/3).

**Revisit:** Update workflow if PR #1 is merged or a real independently resumed agent exposes gaps. The owner must separately authorize any merge, game artifact upload or upstream submission.

### D-005 — 2026-11-26 MST — Fail closed on moving upstream refs and hostless cached device assumptions

**Decision:** Keep the six-PR experimental renderer reconstructible only from explicit upstream SHAs in a disposable checkout. If any upstream PR head moves, stop and compare old/new source and authorship before updating a pin. For #2628 on a capped NVIDIA host, ensure `portable_view_heap` never freezes a host-absent fallback in `OnceLock`; add a pure lifecycle regression and two explicit original portable layout tests to CI.

**Why:** #2626 advanced by exactly one test-only commit after E-049 green CI, correctly triggering an upstream ref mismatch; #2628 previously cached `host().is_some_and(...)` as an irreversible false. A green build and a zero-match filtered test are insufficient for native title safety.

**Alternatives rejected:** silently following changed PR heads, force-applying a changed patch, merging the portable stack into main, disabling strict Clippy, or claiming full descriptor tests after `portable` matched zero.

**Evidence:** E-049 through E-051; [six-PR green CI 45928372350](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45928372350), [upstream #2626 comparison](https://github.com/moe-miau/VIctory/compare/c8cc83e22702aa46dc1855c0f9df890fc5496238...6092548b147639bd5c46e896bcc0cc08fff71542), [PR #5](https://github.com/JohnTWillemsen/VIctory-W/pull/5).

**Revisit:** The new hostless fix at `e536b366` is NOT yet CI proven at the time of this decision. Require exact-head source/Windows run, then native RTX5090 private GPU and game comparison before changing defaults or main. A safer upstream implementation supersedes this experiment only after source review.

### D-006 — 2026-11-26 MST — Two reviewed Python research paths allowed without relaxing game-asset scans

**Decision:** The existing type allowlist is extended ONLY for `scripts/research/e045-reconcile-pr2628.py` and `scripts/research/e049-guard-hostless-portable-probe.py`, both synthetic/public-source exact-preimage helpers. These are **not** entries in the broad binary EXCEPTIONS exemption; unchanged policy still rejects files over 512 KiB, binary magic/NUL, encoded payloads, and every unapproved Python path. Added negative tests. An unrelated repo-wide CI failure should be fixed at the governance level without suppressing tests or publishing title material.

**Evidence:** E-053, [CI policy failure 45932656189](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45932656189) and exact-path PR #5 correction at `6a9787190de810ba560195608f0fc1ee3ce044f3`. Latest CI for fix must be read before calling it PASS.

**Alternatives rejected:** wildcard `py` type approval, EXCEPTIONS (would skip all content checks), renaming executable Python to misleading `.txt`, suppressing policy test, or merging scripts to main before validation.

**Revisit:** If a better script architecture removes the need for these helper files, revoke the two exact paths. Any further path still needs a new review and regression.

### D-007 — 2026-11-26 America/Phoenix / 2026-11-27 UTC — Cross-vendor fixes require exact source proof and separate draft gates

**Decision:** Treat GPU-vendor labels as clues, not compatibility boundaries: Kelvaroq contains public NVIDIA-related patches and user RTX5080/4090 reports; Belobug targets AMD but RTX3090/RTX5070Ti reports expose NVIDIA-relevant behavior. Prioritize **correctness** (illegal host barrier states) ahead of memory/mesh/FPS optimization. Preserve the previous E-047 Kelvaroq audit because its main SHA is unchanged. Port only Belobug PR #449's exact semantics into the **disposable six-PR** reconstruction behind `E056_PATCH=1` in new draft PR #7, with pure synthetic tests and CI, not a merged engine fork.

**Evidence:** E-055/E-056; independent raw-before/legal-after mismatch in VIctory-W `63bcca4`, [Belobug issue #13](https://github.com/Belobug/VIctory-Belobug-AMD/issues/13) NVIDIA D3D12 error, [Belobug PR #449](https://github.com/Belobug/VIctory-Belobug-AMD/pull/449), [E-055 audit](https://github.com/JohnTWillemsen/VIctory-W/blob/3df1d2a1cd141f677106956be1ee775504cc2217/docs/research/e055-kelvaroq-belobug-nvidia-source-audit-20261126.md), [PR #7](https://github.com/JohnTWillemsen/VIctory-W/pull/7).

**Alternatives rejected:** wholesale AMD fork merge (hundreds of divergent commits), Kelvaroq private DXR/UMA claims as proof, importing 64 patch files, blindly replacing Wave64 #439 with PR #442, changing rendering and performance settings simultaneously, or treating synthetic CI PASS as a visible title.

**Revisit:** Wait for E-056 exact-head hosted Windows results; then **after** E-052 private RTX5090 six-PR baseline and owner approval, perform separate A/B debug-layer test. Rollback means close draft PR #7, not reset or alter main. Never publish title artifacts to GitHub.
