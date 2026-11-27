# E-037 — pinned #439 + #2118 + #2098 source-only integration and Windows CI

**Date:** 2026-11-26 America/Phoenix (GitHub run on 2026-11-27 UTC). **Result:** **CI_PASS** on ordinary **Windows GitHub Actions** runner, not a real NVIDIA RTX 5090, not a title run. Source was **reconstructed in a disposable Windows runner checkout and removed at end of job**; no source implementation was pushed to this research branch or merged into `main`. The experiment is reproducible via [the guarded CI script](../../scripts/research/ci-pr439-bvh2118-pr2098.sh) and [workflow](../../.github/workflows/e037-pinned-integration.yml).

- **Successful pinned job:** [E-037 workflow 45922176292](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45922176292), source script commit `38ac51eee48256b2e9dffb41c6162ecbb0bd98ab`, job id `140255207600`. GitHub completed **success**.
- **First guard-stopped run (not hidden):** [45922114152](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45922114152) stopped **exit 6 before applying #2098**, because comparing #2098's old base **tip** against PR head dragged in unrelated `resource.rs`. Fixed via GitHub-style **three-dot merge-base** diff; do not mislabel this as a Rust regression or silently omit it.
- **PR refs pinned:** [#439](https://github.com/Marvisak/VIctory/pull/439) `e2d3cfd50715954fb89ff462edb37a0c4395ecd0`; [#2118](https://github.com/Marvisak/VIctory/pull/2118) `999a8f67125865fcc0b3aa23cdc8a93b10ef9974`; [#2098](https://github.com/Marvisak/VIctory/pull/2098) `543d8688068b658ca4bf9602887097b215fec838`. Older PR #2098 target-tip anchor `219878a0e7754511d89306331812971bb2153f5f`; computed actual merge base `f3578e386ea0f06153445af10a698df029620aad`.
- **Exact reconstructed #439+#2118 index tree before test-only fix:** `9f8bb36f497fdfffd9d68f2f2b22b0284899ae10`; `pipeline.rs` preimage SHA256 `BE8CA499438B8D89B869D58D0749171F62CE92F5860BE2A3A788B5C08D0687AF`, test-only postimage SHA256 `7F172A4D048FE74F8DBFA250F49DB2FD5A816456A849CC824FAA237B52B3CB73`. Test-only `emit::Target::ANY` was already owner-proven E-034 and needed for combined workspace check.
- **Ephemeral local-only integration commit** after #2118 plus test helper repair (before #2098 patch): `f00c8ea1ed28a28c139b4ff115f7c6682af38b81` (**never pushed or created in VIctory-W Git objects**). Subsequent GitHub three-dot #2098 patch changed only `crates/victory-gpu/src/descriptor/host.rs`; `git apply --check --index`, `git apply --index` and `git diff --cached --check` succeeded. **The resulting post-#2098 source state is ephemeral and not a persistent integration SHA**, so avoid calling the temporary commit the full three-PR head.

## Completed hosted Windows gates (not physical GPU)

| Actual command | Log result |
| --- | --- |
| `cargo check --workspace --all-targets --locked` | **exit 0**; dev profile completed |
| `cargo test -p victory-gpu --lib --locked an_acceleration_structures_view_address_is_its_location -- --test-threads=1 --nocapture` | **1 passed, 0 failed, 237 filtered**; checks acceleration-structure location and comparison with ordinary buffer/null views |
| `cargo test -p victory-gpu --lib --locked builder -- --test-threads=1 --nocapture` | **4 passed, 0 failed, 234 filtered**; builder recognition/all-or-none and dropped-dispatch unit cases |
| `cargo build --release --locked -p victory` | **exit 0**; optimized release profile completed |

**Not run:** full shader library suite; entire full GPU suite; physical RTX5090 synthetic shader readbacks for THIS three-PR source state; private title launch, visible scene/texture comparison, hardware BVH execution, device loss, FPS or production runtime artifact. The earlier owner's 38/38 RTX5090 #439+#2118 shader tests and 4/4 BVH are **E-034 on the two-PR code**, not this three-PR build. The two known NVIDIA descriptor-cap full-GPU failures remain unresolved; hosted focused tests do not fix them.

## Findings and next bounded step

1. The first missing render prerequisite (#2098 acceleration-view descriptor address) is **source-applicable and compilable** with the pinned safe console-flow/BVH base; synthetic address behavior passes in hosted Windows CI. Do not claim the title now builds a real BVH or that 3D world is visible; #2098's author specifically warns the correct address is useless until all builder shaders run.
2. Plan a **separate, exact-commit-controlled source integration of #2626** (packed writable-target fallback) with nine changed files; it affects more than one host format descriptor and cannot safely be transplanted by copying just a render target format line. Preserve #439/#2118/#2098 source and their synthetic test before any further source merge. Other pending fixes #2464 raw structured SRVs and #2628 shader/descriptor cap must still be reconciled.
3. Before a private RTX5090 title probe, obtain a **persistent, exact-source reviewed integration build** on a new dedicated experimental branch/worktree; do not use the E-037 ephemeral local-only commit as a downloadable or verified owner-executable identifier. Add focused validation on owner's hardware, then compare strictly matched scenes, flags and native log reasons. Keep all logs/screenshots/game files private.
4. No main merge, original build replacement, owner hardware intervention, source author PR or title material in Git was performed for E-037. Guard against false conclusion from ordinary Windows CI GPU-optional tests.

**Decision:** Source-level E-037 **TESTED on Windows CI** only, proceed to other source prerequisites as controlled candidates; no `GAMEPLAY_OBSERVED` tag and no `GPU_PASS` for the three-PR source.
