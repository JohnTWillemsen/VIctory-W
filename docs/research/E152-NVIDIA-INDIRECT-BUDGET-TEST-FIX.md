# E152 — NVIDIA indirect budget tests: narrow upstream correction

Date: 2026-11-27 America/Phoenix. Source base `ea186566a868430a51e416d4c94695f6aff3fce1` on `JohnTWillemsen/VIctory-W` live `main` at branch creation. Work branch `test/e152-nvidia-indirect-budget-regression-20261127`. **Draft, not a gameplay/performance fix.**

## Reproduced on existing CI

Windows Actions E127 full tests [run 46100529280](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46100529280) ran 472 GPU test cases: 433 pass, 3 fail, 36 ignored. Two indirect budget failures were:

- `indirect::tests::host_list_budget_starts_empty_at_each_submission`: expected small dispatch skipped after budget exhausted, observed 1. Old fixture supplied three identical 65,535 × 16 × 64-thread records. Under `VICTORY_INDIRECT_REST=0` (documented default) a record too large for the remaining budget is skipped rather than consuming remaining budget; after two huge records the third was not eligible, leaving room for a small dispatch.
- `indirect::tests::warp_batch_charges_every_execution`: expected every oversize record to consume the budget, observed zero consumption. The fixture had assumed saturation regardless of the `VICTORY_INDIRECT_REST` setting.

Unchanged and still separately failing: `pipeline::host::tests::depth_bounds_pipeline_loads_and_filters_draws`. Strict Clippy remains a separate gate. None of these test outcomes prove visual correctness or gameplay.

## Source provenance and isolated change

Upstream NVIDIA source commit [9b712a6](https://github.com/trustno1-coder/VIctory-NVIDIA/commit/9b712a6ab2f4de6f5fc0f30396821029a2ac15ef) fixes these exact outdated fixtures on the same NVIDIA renderer. Reviewed the actual fork's `crates/victory-gpu/src/indirect.rs` before editing; only three scoped replacements made under `#[cfg(test)]`: two large records plus a small record to exactly exhaust the budget, and an explicit expected-charge fold accounting for REST disabled or enabled. **No production renderer code is changed.**

`.github/workflows/e152-nvidia-indirect-rest.yml` tests exactly this PR source SHA on Windows WARP with both `VICTORY_INDIRECT_REST=0` and `=1`, each of the two cases serialized and explicitly checked. Full suite remains unmodified and must not be relabeled green until all inherited failures really pass.

## Gates and rollback

- Required: exact-head E152 Windows WARP test pass; release build/harness privacy gates stay independent.
- Required: source diff review ensures only test fixture semantics changed; no game, logs, shaders, binaries, title contents or private owner data were collected.
- Not run here: title/RTX5090 play, stability, performance A/B, visuals, controls.
- Rollback: close draft PR or revert the single `indirect.rs` fixture edit. Keep PR50 draft and the main source untouched.

## Priority

P0 still PR50 owner visual/control acceptance and further isolated performance investigation. This E152 test correction is P1 CI-noise reduction to improve confidence in future renderer experiments, not a substitute for real-world playability.
