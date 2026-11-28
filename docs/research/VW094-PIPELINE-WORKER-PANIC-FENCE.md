# VW094 — per-pipeline panic fence in NVIDIA host pipeline workers

**Status:** isolated SOURCE IMPLEMENTATION, DRAFT, **no owner GPU run or gameplay effect proven**. Base is current verified NVIDIA main `ea186566a868430a51e416d4c94695f6aff3fce1`, source v2026.11.27.8.

## Source provenance and the actual bug

During upstream sweep (2026-11-28 UTC), NVIDIA `trustno1-coder/VIctory-NVIDIA` `main` `63b902fe1720a5188ee79d94a88c8de0470f6349` was **56 commits ahead** of our pinned `64d4931b3dd90305134512b805fc98f04119fb6e`. Compare [upstream](https://github.com/trustno1-coder/VIctory-NVIDIA/compare/64d4931b...63b902f). Its `crates/victory-gpu/src/pipeline/make.rs` adds `catch_unwind` around a *single host pipeline build* (not around the whole worker). This is a real source-level correctness fix: a panic in `OnceLock::get_or_init` leaves the key uninitialized, aborts the worker thread and can leave a queued pipeline/waiters forever incomplete, rather than resolving that pipeline as unavailable.

## Narrow actual implementation

- `Pending::make` delegates to `make_with`, where only the per-pipeline construction closure is wrapped in `catch_unwind(AssertUnwindSafe(...))`.
- On panic the specific pending pipeline is stored as `None` inside its `OnceLock`, preventing repeated builds and preserving the next worker job.
- `DONE` Condvar is still notified on every completed build, including refused ones.
- Existing ordinary success paths, pipeline ordering, frame wait budgets, shader translation code, caches, GPU state, and E127 scripts are unchanged.
- A new Rust regression creates two fake pending pipelines, panics one, then proves the worker continues and both keys are resolved; repeated attempt at the failed key is ignored.
- The dedicated exact-head Windows CI runs this test and `cargo check --locked -p victory`. No game or private resources are in CI.

## Acceptance and limits

This addresses an actual exceptional path. **It does not prove H4's 9.9 FPS window or any observed GPU crash was caused by a Rust panic**, and it is not a new FPS improvement. A panic may indicate a deeper correctness problem: now the pipeline is conservatively refused rather than leaving workers blocked, while an error is logged privately. Full source/Windows CI must pass. No owner RTX5090 run justified merely for this new defensive source fix. Keep the exact known-good H4 executable SHA256 `70e0bbe0ed7aa032a65495a99f26240310acdeeb1337927002b1a6460a801d60`, original private persistent cache and saves intact; never silently merge this branch with PR61 or VW093.

GPL-3.0 upstream source provenance retained; no game/title data included.
