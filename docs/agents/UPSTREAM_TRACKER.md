# Upstream candidate tracker — research queue, NOT merge approvals

**Snapshot date:** 2026-11-26. Upstream PR heads, dispositions, implementation and test claims change; **requery live GitHub before taking action**. Every row is an idea to investigate, not proof of absence in current Marvisak `main`. Work on one at a time.

| Candidate | Why investigate | Required first check | Disposition at this snapshot |
| --- | --- | --- | --- |
| [fxceless #927](https://github.com/fxceless/victory-fork/pull/927) | Lossless 16-bit GPU typed-buffer movement reportedly restores animated faces on RTX 5080 | Check source and Marvisak equivalent; 16-bit descriptor semantics, synthetic bits roundtrip, all dependencies and relevant graphics | `UNVERIFIED` in VIctory-W; `UPSTREAM_REPORTED` only |
| [fxceless #1246](https://github.com/fxceless/victory-fork/pull/1246) | Bindless texture queue fairness reportedly reduces black/red faces under streaming | Check if current `TextureQueue` already alternates/weights due slots; compare test and separate heap-worker dependency | `UNVERIFIED` in VIctory-W; no automatic cherry-pick |
| [fxceless #1234](https://github.com/fxceless/victory-fork/pull/1234) | Limit repeated per-frame waits on pending pipelines | Check current pending-frame/queue logic and whether skipped draws would create a correctness regression | `UNVERIFIED` in VIctory-W; performance experiment only |
| [fxceless #992](https://github.com/fxceless/victory-fork/pull/992) | RTX 5090 microbench reports faster wide GPU hash passes | Verify hash code already present, data integrity, WARP coverage and end-to-end GPU/CPU cost; microbench is **not** FPS proof | `UNVERIFIED` in VIctory-W |
| [Marvisak/VIctory](https://github.com/Marvisak/VIctory/pulls) latest pull requests | Our preferred destination for general fixes | Filter for same behavior before coding; new upstream may already solve the problem | `UNKNOWN` until a focused live issue/PR scan |

### Research record for each candidate

Add a dated subsection containing (1) original PR and author, (2) checked exact source head SHA, (3) latest upstream `main` SHA, (4) actual file and implementation comparison, (5) dependencies/licensing, (6) user-visible symptom and negative test, (7) synthetic/GPU evidence by **environment**, (8) decision: `DUPLICATE`, `CANDIDATE`, `STAGED`, `TESTED`, `REJECTED`, `UNKNOWN`.

Do not call a fix integrated based on a title, GitHub's 'mergeable' flag, or someone else's unverified performance screenshot.
