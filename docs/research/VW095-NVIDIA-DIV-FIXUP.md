# VW095 — NVIDIA shader division fixup correctness (isolated source port)

**Status:** draft source change on `fix/vw095-nvidia-div-fixup-20261128`; **no owner game or GPU run**. Base `ea186566a868430a51e416d4c94695f6aff3fce1`, upstream source commit [`feb90adeb11c9be0cd842c923463b7afbe2e5a30`](https://github.com/trustno1-coder/VIctory-NVIDIA/commit/feb90adeb11c9be0cd842c923463b7afbe2e5a30). This is a narrow upstream fix, not wholesale adoption of a newer NVIDIA release.

## Why change the runtime

The pinned NVIDIA foundation still carries division-fixup code that promotes a NaN intermediate quotient to infinity too early. Upstream fixed the priority so zero/infinite input operands are resolved before treating the intermediate NaN quotient as decisive, while retaining sign and invalid-operand behavior. In particular, a NaN quotient is not by itself proof that a finite numerator divided by a nonzero denominator should become infinity.

## Scope

- `crates/victory-shader/src/emit/lower.rs`: port upstream's **specific** `v_div_fixup_f32` select priority correction.
- `crates/victory-shader/src/emit/mod.rs`: port upstream's synthetic compute fixture that independently supplies the quotient, denominator and numerator (including NaN, zero, infinity and sign corners). The CPU-only lowering check is separate from a **Windows GPU execution regression intentionally ignored by default**; the ignored test does not count as passed.
- `.github/workflows/vw095-div-fixup.yml`: dedicated Windows exact-source-head CPU-only shader lowering regression and locked `victory` source check; no game assets, launches, or GPU benchmarking.

## Preconditions and limits

GitHub live `main` at `ea186566a868430a51e416d4c94695f6aff3fce1` still contained the pre-fix branch and upstream fixture was absent (SOURCE_READ). Recent draft PRs #50, #56, #57, #60, #61, #62 and #63 have **no changed file overlap** with the two shader paths (PR filename checks, 2026-11-28 UTC). Standard CI and full synthetic WARP checks have known pre-existing reds; do not waive them or claim full green. The source fix is not measured to increase FPS or to cure stutter, progression or graphical defects on RTX5090.

## Review/acceptance

1. Verify exact-head dedicated Windows workflow and source compile; retain inherited failures by check name, not overall workflow color.
2. Evaluate the GPU-dependent ignored upstream regression only in a safe explicitly opted-in environment and never confuse it with a title session.
3. If source gates pass, preserve the existing RTX5090 known-good H4 binary/cache; consider a **later** controlled E127 visual A/B only if needed and explicitly authorized with literal PLAY. No replay or game launch is requested for this PR.
4. Do not merge automatically. Rollback: leave this draft unmerged; `main` unchanged. Preserve upstream GPL provenance and asset policy.
