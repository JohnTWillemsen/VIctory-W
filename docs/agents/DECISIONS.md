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

## D-008 · 2026-11-26 MST / 2026-11-27 UTC — E-056 passes synthetic RTX5090 but requires visual A/B before promotion

**Decision:** Accept E-060/PR #8 (Belobug #449 legal BEFORE/AFTER D3D12 state correction under `E056_PATCH=1`) as a passing **isolated synthetic owner RTX 5090 hardware experiment**, not a verified game graphics correction. Use the successful independently preserved E-052 six-PR baseline and separately built E-060 candidate for a controlled *owner-performed* E-062 title visual A/B, with identical title bytes and graphics settings, one executable at a time, unchanged driver and no background GPU load where feasible. Record whether first rendered scene appears, relevant errors, crash/stall, qualitative differences; ask owner to upload only private ZIP/log/screenshot evidence within ChatGPT, never publicly.

**Evidence:** E-058 baseline 303 executed tests pass and one ignored; E-061 E-060 barrier synthetic 311 executions pass and one ignored on RTX5090 driver 617.42, four additional E-056 tests per focused and full library run. [PR #8](https://github.com/JohnTWillemsen/VIctory-W/pull/8), [CI 45936578198](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45936578198) all jobs pass. Candidate source-generated binary hash `5e378b0e3673059cbbffcee54f0d83cedbde00ff0f40522136022e2dc469c723`.

**Not established:** In-game D3D12 debug error 523 behavior, world rendering, title stability/FPS and any performance gain. Initial E-060 Bash typo and its failed CI remain historical (corrected). No auto-merge to main or public proprietary artifact uploads.

## D-009 · 2026-11-26 MST / 2026-11-27 UTC — Do not promote D3D12 barrier fix based on unmatched visuals

**Decision:** Maintain isolated E056 barrier candidate PRs #7–#9 as experiments; E062 owner actual runs reached intro/audio but no correct world, and D3D12 debug layer was not enabled so error ID 523 remains untested. Visible sequence differences can be due to warmed/shared cache or the progress of each run; not enough to claim E056 fixes RTX5090 rendering. Independent research priorities: (1) source evidence for BVH builder **7/53 refused** pipelines and unavailable NVIDIA native wave64, (2) deterministic 507331 warnings from descriptor `HIGHEST` max-only logger, and whether host heap capability affects actual reachable slots, (3) optional later owner-approved debug-layer A/B on the same title scene.

**Privacy:** Raw private game logs and identifiers must not be put into the public repository, including shader hashes originating from title content, addresses or screenshots. Sanitize aggregation only.

**Revisit:** After bounded source fix/gate with synthetic tests and stable owner hardware evidence; a no-scene or gray result alone is not proof of a specific subsystem cause. Main untouched.

## D-010 · 2026-11-26 MST / 2026-11-27 UTC — Diagnose NVIDIA BVH blockers before changing shader semantics

**Decision:** Do not convert seven missing BVH pipelines into unconditional dispatches; [Marvisak #2118](https://github.com/Marvisak/VIctory/blob/999a8f67125865fcc0b3aa23cdc8a93b10ef9974/crates/victory-gpu/src/pipeline/builder.rs) intentionally suppresses all builder work if any pipeline is absent to prevent corrupt acceleration-structure writes. Source inspection of [#439](https://github.com/Marvisak/VIctory/blob/e2d3cfd50715954fb89ff462edb37a0c4395ecd0/crates/victory-shader/src/emit/lower.rs) shows why arbitrary wave64 groups larger than 64 threads, implicit derivatives and LDS/title-memory operations are guarded on 32-lane NVIDIA. Replacing guards with success without semantically sound emulation is rejected.

**Implementation:** Separate independently gated source-only research PR10 (optional rate limiting of repetitive descriptor warnings; runtime return unchanged) from PR11 (opt-in anonymous missing-builder pipeline category counter using shader translation/pipeline state; all-or-none predicate unchanged). Both source jobs passed, Windows full gates pending as of initial observation. No merging to main and no game title assets.

**Next:** Verify exact-head CI; if green, plan one bounded RTX5090 build to collect *anonymous* builder-category evidence, rather than full unfocused visual A/B loops. Keep E065 warning rate limiting separate in the first hardware comparison, or explicitly document a later combined experiment.

## D-011 · 2026-11-26 MST / 2026-11-27 UTC — One owner-gated anonymous BVH category run, no full visual A/B

**Decision:** After E064 title A/B established gray/incomplete world on both E052/E060, use E068 diagnostics to determine whether the seven refused builder host pipelines are from shader translation vs D3D12 host creation; do not rerun old full GPU test battery or merge E056 based on visual guesses. Combine **only** E065 (logs sampled, descriptor `return None` unchanged) and E066 (aggregate anonymous categories, all-made BVH safety gate unchanged) in an isolated source-only rebuild. Require exact pinned source/PS parser and full Windows Clippy/release validation before owner trial; owner must explicitly type LAUNCH for a single existing local game executable. Keep raw title logs entirely on owner's machine outside ZIP; package anonymous counts and non-sensitive metadata only.

**Success/limits:** Numeric category sums may guide next focused shader or D3D12 investigation, but do not prove a graphics fix, correct world rendering, or seven unique pipeline causes unless totals observed. If counts missing, say unknown rather than infer zero. Separate E065 standard repo-wide frame ticking test failed; record it rather than labeling flaky.

**Rollback:** Draft PR #12 source branch may be closed without affecting main/E052/E060. No title-derived code/data in GitHub.

## D-012 · 2026-11-26 MST / 2026-11-27 UTC — Preserve partial-world render evidence; investigate absent E-068 categories offline first

**Decision:** The owner privately demonstrated a real partially rendered illuminated distant city scene on RTX5090 with E068 source-generated six-PR+E065/E066 diagnostic-only candidate; most foreground/scene remains black and unrendered. Do not describe as playable or a proven E065/E066 graphics repair, since changes only affect logging and category output, which may affect timing and cache. E068 summary explicitly lacks anonymous BVH counts and that is **unknown**, not zero refused. Existing raw stderr/stdout remain in the owner's local PRIVATE folder.

**Next test:** Read-only E070 offline stream of those already-existing private logs to check if BVH summary line appeared, and whether opt-in category marker exists or had unparseable numeric fields. Never ask for another gameplay rerun until existing logs analyzed. Only numeric ZIP supplied privately, game screenshot/raw logs never committed publicly. CI for offline tool passed exact-head PowerShell 5.1 synthetic parser/redaction at `97574a6`.

**No main merge** and no attribution of visual difference without comparable scene/time/cache-controlled baseline.

## D-013 · 2026-11-26 MST / 2026-11-27 UTC — Target BVH shader translator semantics, not D3D12 PSO refusals

**Decision and evidence:** Corrected private E070 offline report (owner RTX5090 E068 logs) proves **7 of 7 BVH builder refused pipelines are failed shader translations**, host-pipeline refusal=0, pending=0. BVH safety predicate remains necessary and unmodified. This narrows the immediate investigation away from host D3D12 pipeline creation; it does **not** establish which unsupported wave64/implicit-derivative/LDS/lane-mask operation accounts for the seven, or that the BVH work alone causes missing geometry.

**Implementation:** Keep E074 independent and opt-in. Classify original shader error text into anonymous broad enum in memory on translation failure, report per-BVH-refused-pipeline count only with explicit flags, no shader hashes, game-derived identifiers, raw errors or title assets. Preserve all original translator/host behavior and all-or-nothing BVH gate. Reject workarounds that simply force acceptance of unknown wave64 group semantics. After strict Windows CI PASS, one bounded owner-approved diagnostic build may be appropriate.

**Privacy:** Private raw E068 logs and screenshots are outside public GitHub; only numeric E070 category totals appear in E073 evidence. Main unchanged.

## D-014 · 2026-11-26 MST / 2026-11-27 UTC — Run only one opt-in RTX5090 E075 histogram after strict CI, continue GitHub engineering independently

**Decision:** E073 measured exactly seven BVH shader-translation failures, zero host D3D12 PSO or pending. E074 shader-operation category source patch has passed both exact-head source and hosted Windows checks/strict Clippy/tests/release. Before attempting any semantic wave64 implementation, use an **E075 one-run owner-gated** source-generated diagnostic build that reports only broad per-refused-builder classes. Do not force acceptance of unsupported wave64 groups, bypass all-made BVH safety, or transplant broad upstream PRs without isolated code + regression validation.

**Boundaries:** Owner approves only the title launch when explicitly typing LAUNCH; no automatic title execution. Never upload raw game logs, paths, shader hashes or game-derived screenshots publicly. Anonymous counts and code provenance are sufficient. User has authorized autonomous engineering/orchestration within interactive session; only request their machine for downloads and commands, not routine source review/PR approvals. No promises of asynchronous coding between turns without a configured scheduler. Main untouched.

**Next:** Verify exact E075 Windows CI, provide one pinned PowerShell command when safe, interpret only anonymized reasons observed. If numbers missing, use the already preserved private logs and offline parser; avoid repeating title unnecessarily.

## D-015 · 2026-11-26 MST / 2026-11-27 UTC — Optimize for first usable gameplay while preserving BVH safety

**Decision:** Measure and fix the seven known BVH shader translation failures (E075 owner reason class histogram) as P0; concurrently research upstream #2925 safe LDS lighting phases and #3406 smaller eligibility patch for visible foreground/scene, without full patch stack transplant. Keep D3D12 barrier divergence in #2214 rejected until upstream correct uniform synchronization and reproducible tests. Only use owner source-generated private runtime tests with named script and small anonymous ZIP. Preserve no raw title/game data in public GitHub.

**Secondary engineering:** Opt-in E077 #2311-derived walker guard prevents ray traversal until builder's structures are whole; its exact upstream delta conflicted with six-PR baseline so a smaller tested two-file port was developed, preserving original all-made BVH gate. This can reduce GPU hang risk while **not** fixing missing lighting/geometry; do not advertise as playability fix without GPU proof. Hosted Windows checks must pass. Main remains unchanged.

**Acceptance:** Owner must actually see foreground/buildings/UI correct, demonstrate input movement, no device hang in bounded run, and eventually provide stable measured frame times; intro/audio/city lights alone do not establish playable state.

## D-016 · 2026-11-26 MST / 2026-11-27 UTC — Reuse successful owner E075 build, do not waste time recompiling after declined launch

**Owner evidence:** E075 compiled public-source-only diagnostics successfully but never launched the title: `BUILD_PASS_OWNER_DECLINED_LAUNCH`, SHA256 `7b978f8f902f27a0ff479142f044d58c1c337526d9ef33cf5b34d3c2b5178f74`. There are no E075 per-BVH shader semantic classifications to interpret. Reusing same binary is safe and efficient as long as hash, local game title input and physical RTX5090 are verified.

**Action:** New E078 opt-in, launch-only PowerShell wrapper; exact existing E075 source-built binary hash required, public parser hash pinned, never recompile. Owner types uppercase LAUNCH before a single title execution and uploads ONLY numeric summary ZIP privately; raw title logs stay local. The script is independent draft PR17 with exact-head WinPS5.1 static consent/privacy CI successful. No other title tests required until data available.

**Parallel engineering:** E077 upstream #2311-derived safe walker holdback passed strict source+Windows CI; remains opt-in, not a title-tested graphics fix. Continue toward playable scene by fixing evidence-backed shader semantics and independently testing lighting/geometry, not conflating warning suppression/safety-only changes with rendering repair. No main merge without approval.

## D-017 · 2026-11-27 00:24 MST — Address five >64-group refusals safely, audit two broadly classified LDS errors

Owner-private E078 verified an actual RTX5090 one-title diagnostic exit 0 and seven builder shader-translation refusals among 53 pipelines. First-error broad categories 5 `large_group` / 2 `cross_half_lds`; the LDS classifier matches general error strings, not exact operations. This is not a successful world render or fps benchmark. Prior E078 NOT_RUN text is superseded for this specific run, but past findings stay append-only.

**Decision:** No bypass of BVH builder all-made safety. #2214 `b3efa1c0e3b7848cdc45d071972c4bfde83627aa` author acknowledges undefined count-paired group barrier across divergence—reject until site-uniform synchronization is correctly specified and negative synthetic tests pass. Independently gate <=64-thread source-only #3406 and separately #2925 lighting; preserve E077 optional walker safeguard. Do not repeat title until bounded source/CI/GPU tests justify a controlled owner run. E078 dedicated CI `45955222863` PASS; ordinary suite `45955222934` FAIL known frame assertion. [E080 plan](../research/e080-bvh-wave64-recovery-plan-20261127.md). Main `63bcca43` untouched. Fork currently publicly visible, keep private title data out of GitHub.

## D-018 · 2026-11-27 ~00:33 MST — Fail closed on the six-PR versus #3406 LDS lowering conflict

**Actual result:** E081 [draft PR18](https://github.com/JohnTWillemsen/VIctory-W/pull/18) head `4253784f7066e55f6f6902b23417dd9b1ed9b586`, dedicated source [CI 45959180895](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45959180895) reconstructed six PRs including explicit #2628 reconciliation, but refused upstream #3406 `git apply --check` at `emit/lower.rs:599` (exit 81); no patch applied and Windows synthetics skipped. [Source audit](https://github.com/JohnTWillemsen/VIctory-W/blob/4253784f7066e55f6f6902b23417dd9b1ed9b586/docs/research/e081-lds-source-compatibility-audit-20261127.md) reads the #439 Target/console-flow/split code and #3406 simple wave-size selector: blindly transplanting the missing hunk could bypass safe behavior. The broad E078 cross_half_lds category does not prove any of the two programs meet #3406 <=64 LDS predicate.

**Decision:** Do **not** accept --3way, accept rejects, force a `WaveSize` override, or report GPU success from the failed source gate. Preserve original BVH all-or-none builder and E077 walker guard. New dedicated exact-preimage semantic adapter needs positive/negative synthetic tests across >=128 group, divergent/guarded/indirect LDS, mask as data, readfirstlane and host Target before any native RTX test. #2214 divergent count-based group barriers remain rejected. Main unchanged; keep private game data out of public repository.

**Related source drift:** #2118 upstream `999a8f671...` -> `78f36cfa...` is exactly one descendant warning-only draw.rs change (+4/-1); retain earlier compiled six-PR baseline until separately approved rebase. E081 source wrapper checks this drift on ephemeral clone only. Ordinary inherited workflows on PR18 that use old exact head fail closed, not new gameplay regressions.

## D-019 · 2026-11-27 MST — Reuse existing E078 raw owner logs to refine shader failure categories

**Decision:** Prefer targeted *offline-only* E082 private log scan over repeating slow owner title execution or rebuilding E075/E078. We have seven builder translator failures and an anonymous E074 per-first-failed-shader 5 large group/2 broad LDS classification; the existing pipeline warning code prints more precise `error=%e` in local title-wide stderr. The new owner script at [PR19](https://github.com/JohnTWillemsen/VIctory-W/pull/19) `0e83b23e6059732769b5dd4d8976c5593a03874e` extracts only fixed integer counters, produces one numeric-only ZIP, and never invokes executable or downloads more code itself. [WinPS5.1 exact-head CI 45960124766](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45960124766) PASS on six fictional warning examples and privacy/AST assertions. **Owner offline scan awaits uploaded result; no real count claims until then.** The title-wide error split is *not* a direct per-builder attribution, and unknown errors remain `other_unclassified`. No unsafe wave64 or BVH barrier import, no main merge. Preserve E081 source conflict and E077 walker safety notes.

## D-020 · 2026-11-27 MST — E082 results change priority to correctness-safe multi-wave (>64) execution

**Evidence:** The owner uploaded E082 anonymous fixed-count report and every one of 43 title-wide shader warnings is classified: **31 group>64, seven implicit derivatives, two lane-mask data, three whole-wave**; 0 ds_permute, explicit cross-half phrase, generic LDS, unknown. Two complete *separate* per-BVH reason records remain five large-group and two broad LDS/whole-wave. The old E074 `cross_half_lds` key includes `whole-wave` and does **not** prove a cross-half opcode. The three title-wide whole-wave warnings are not provably the same two BVH shaders. No re-execution of the game/GPU occurred.

**Decision:** P0 engineer safe Wave64-on-Wave32 group>64 execution with a group-uniform barrier rendezvous and strict **static call-site** invariants, no count-only matching. [Microsoft documents](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/groupmemorybarrierwithgroupsync) that group-sync behavior within divergent thread-group branches is undefined. Upstream #2214 at `b3efa1c0e3b7848cdc45d071972c4bfde83627aa` currently pairs barriers by observed count while host waves can take different branches/sites; do **not** import as-is. Start with host-independent synthetic adversarial model for loop divergence, early exits, calls at different sites with same epoch, incomplete groups and wave count; then source-only integration guarded by exact preimages, native Windows GPU/validator tests, and only after full green candidate an owner-approved physical RTX5090 A/B. Preserve E077 walker protection and all-or-none BVH builder. Keep PR18 #3406 safe <=64 adaptation tracked as secondary. No new owner command yet; no main merge.
