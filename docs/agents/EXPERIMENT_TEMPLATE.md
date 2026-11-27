# Experiment / bug report template (copy per focused PR)

**Hypothesis:** (one falsifiable behavior, never a promised FPS gain)

**Source and provenance:** original issue/PR/author/commit/URL/license; any dependent PRs or experimental switches.

**Current baseline:** repository; exact full SHA; Windows/Rust/driver versions where relevant; source paths actually inspected; existing feature flags; known duplicate fixes.

**Observed failure:** diagnostic signature and reproducible steps. Mark `UPSTREAM_REPORTED` if only another author's hardware; use `UNKNOWN` when not reproduced. Store private data locally, **not** in Git.

**Minimal implementation:** changed source paths, safety/lifetime reasoning, why this is a better adaptation than a blind cherry-pick, fallback/rollback variable if needed.

**Control vs candidate:** two exact binary hashes / source SHAs; equivalent title build, scene, profile, resolution, same cache state, same driver and diagnostic options.

**Tests:**
- `NOT_RUN / UNIT_PASS / WARP_PASS / CI_PASS / GPU_PASS / GAMEPLAY_OBSERVED` with direct links, actual commands, pass/fail and limitations.
- One negative/regression test that would fail before the fix and pass after.
- Exact CI head SHA; avoid claims from unrelated runs.

**Picture vs frame rate:** geometry/walls, NPC/face/hair, shadow/light, texture/water, HUD/controller, draws discarded, median/p95/p99 ms/frame and GPU/device resets. Higher FPS with missing world draws fails.

**Result:** confirmed / refuted / inconclusive, with scoped evidence; risk; reversal procedure; unresolved hardware check.

**Next action:** bounded next test or PR reviewer decision. Update CURRENT_STATE; append EVIDENCE_LOG for real observations, DECISIONS for acceptance/rejection.
