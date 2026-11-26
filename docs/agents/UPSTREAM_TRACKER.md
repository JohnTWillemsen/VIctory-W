# Upstream candidate tracker — research queue, NOT merge approvals

**Snapshot date:** 2026-11-26. Upstream PR heads, dispositions, implementation and test claims change; **requery live GitHub before taking action**. Every row is an idea to investigate, not proof of absence in current Marvisak `main`. Work on one at a time.

| Candidate | Why investigate | Required first check | Disposition at this snapshot |
| --- | --- | --- | --- |
| [fxceless #927](https://github.com/fxceless/victory-fork/pull/927) | Lossless 16-bit GPU typed-buffer movement reportedly restores animated faces on RTX 5080 | Check source and Marvisak equivalent; 16-bit descriptor semantics, synthetic bits roundtrip, all dependencies and relevant graphics | `UNVERIFIED` in VIctory-W; `UPSTREAM_REPORTED` only |
| [fxceless #1246](https://github.com/fxceless/victory-fork/pull/1246) | Bindless texture queue fairness reportedly reduces black/red faces under streaming | Check if current `TextureQueue` already alternates/weights due slots; compare test and separate heap-worker dependency | `UNVERIFIED` in VIctory-W; no automatic cherry-pick |
| [fxceless #1234](https://github.com/fxceless/victory-fork/pull/1234) | Limit repeated per-frame waits on pending pipelines | Check current pending-frame/queue logic and whether skipped draws would create a correctness regression | `UNVERIFIED` in VIctory-W; performance experiment only |
| [fxceless #992](https://github.com/fxceless/victory-fork/pull/992) | RTX 5090 microbench reports faster wide GPU hash passes | Verify hash code already present, data integrity, WARP coverage and end-to-end GPU/CPU cost; microbench is **not** FPS proof | `UNVERIFIED` in VIctory-W |
| [Marvisak/VIctory](https://github.com/Marvisak/VIctory/pulls) latest pull requests | Our preferred destination for general fixes | Filter for same behavior before coding; new upstream may already solve the problem | `UNKNOWN` until a focused live issue/PR scan |

### NVIDIA heap candidate comparison — 2026-11-26 refreshed

These are **distinct and potentially conflicting approaches** on original `main` `63bcca43c6a00a758510398fa43096ce7e4f7df0`, not a recipe to combine them. Always verify fresh heads and upstream claims before editing.

| Upstream source | Pinned last-known head / status | Evidence and caveat |
| --- | --- | --- |
| [#3300](https://github.com/Marvisak/VIctory/pull/3300) — scale dynamic pool on capped view heaps | `01f91fea96de7c6fe47d5dd9f302e51a2403cac7` OPEN | **Owner UNIT_PASS** on Windows RTX 5090 driver 617.42: **16 descriptor-host tests passed**, including previously failing `dynamic_slots_are_held_until_released`. Keeps more dynamic slots, potentially sacrificing title slots on 1M-capped hardware. Not proven to render better. |
| [#2683](https://github.com/Marvisak/VIctory/pull/2683) — conservative 1M heap/index clamp | `aecd60423c4673233104afaba1bde81f40d78a93` OPEN | Updated/rebased 2026-11-26; null-view boundary tests added. **Owner UNIT_PASS (RTX 5090 environment)**: `cargo test -p victory-gpu --lib --locked descriptor:: -- --test-threads=1 --nocapture` 24 pass / 0 fail / 210 filtered, including clamp boundary tests and baseline's failing dynamic-slot test. Not a graphics/gameplay claim. Discards accesses to title indices beyond capped layout; prevents out-of-range rather than restoring full indexing. |
| [#2121](https://github.com/Marvisak/VIctory/pull/2121) — page title view heaps | `0bc5edbd2e1c5836bab00dc0af9f186bdd56c608` OPEN | Larger runtime/shader changes. Upstream reviewers have synthetic reclamation tests and mixed old/new gameplay observations; latest head needs new controlled A/B due to material paging fixes. **OWNER NOT_RUN**. |
| [#3244](https://github.com/Marvisak/VIctory/pull/3244) and [#2937](https://github.com/Marvisak/VIctory/pull/2937) — revise capped-host test premises | OPEN; exact head recheck required | Distinct test changes. Original main's 2M-size assertion is false on NVIDIA. Avoid duplicate fixes; [#1633](https://github.com/Marvisak/VIctory/issues/1633) task `NEW-24` already claimed. |
| [#3370](https://github.com/Marvisak/VIctory/pull/3370) — dynamic slot table bounds/overflow | `9d84d108b7dd9f603e9695afa47b38835fcb9b0c` OPEN at last review | Upstream reviewers report NVIDIA RTX5090 synthetic results; **UPSTREAM_REPORTED**, not ours. Potential overlap with #3300/#2121. |

See [CURRENT_STATE](CURRENT_STATE.md) for owner test commands/results and [EVIDENCE_LOG](EVIDENCE_LOG.md) for durable evidence. Do not copy this dated table into an implementation PR without rechecking actual code and license.

### Research record for each candidate

Add a dated subsection containing (1) original PR and author, (2) checked exact source head SHA, (3) latest upstream `main` SHA, (4) actual file and implementation comparison, (5) dependencies/licensing, (6) user-visible symptom and negative test, (7) synthetic/GPU evidence by **environment**, (8) decision: `DUPLICATE`, `CANDIDATE`, `STAGED`, `TESTED`, `REJECTED`, `UNKNOWN`.

Do not call a fix integrated based on a title, GitHub's 'mergeable' flag, or someone else's unverified performance screenshot.
