# E108 — Integrate wave-aware group barrier lowering from upstream PR #2920 (isolated RTX5090 candidate)

**Parent:** [staged upstream #3409](https://github.com/JohnTWillemsen/VIctory-W/pull/27) exact fork commit `712325801d17466c5ce6ff85d96065a5a22814e1`, whose upstream source head is `965d93823587932e8f40b152b8d4faab5f7a9c85`. User NVIDIA RTX5090 run E087 v2: 96s before `0x887A0005` device removal, 16 in-flight DRED **DISPATCH occurrences** possibly duplicates, no identifying shader; original upstream #3409 batch title run hardware corrected to AMD integrated GPU. **Do not claim NVIDIA gameplay.**

## Source change
Strictly reapply the **complete upstream public-source [Marvisak/VIctory PR #2920](https://github.com/Marvisak/VIctory/pull/2920)** patch (source head `ef794e8c32ce92365775eaeea16abb912a07f324`, original author [@lhnizdo](https://github.com/lhnizdo)) on staged PR27, not on `main`; all **18 existing-file hunks** were exact unique matches and two new files were absent. Changed exactly the five upstream files:

- `crates/victory-shader/src/emit/lower.rs`
- `crates/victory-shader/src/emit/lower/barriers.rs` (new)
- `crates/victory-shader/src/emit/barrier_tests.rs` (new)
- `crates/victory-shader/src/emit/mod.rs`
- `crates/victory-shader/src/structure.rs`

The patch aims to let different lanes of an emulated console wave reach group barriers under divergent control flow, introducing barrier balancing and console-wave mode for otherwise unbalanced branches. This is a **shader codegen/semantics change**, unlike E105's diagnostic text-only modification. Upstream #2920 claims RTX2080 title gameplay with **several additional NVIDIA fixes**. This experiment is **not proof the patch alone is causal**. Wave64/mesh hangs from upstream [issue #71](https://github.com/Marvisak/VIctory/issues/71) and owner DRED do not identify the failing program. No arbitrary skip of compute pipelines or TDR setting changes.

## Acceptance and tests
Exact-source gate before any merge or owner invocation: checkout of staged branch, strict Git blob inventory, Windows locked full workspace Clippy default/all features, full workspace tests, cargo Rust release diagnostics executable build. Archive a source-only `victory.exe` plus fixed manifest with upstream source provenance and SHA256 on full success; never upload title content. Parent PR27 already has a Windows artifact but owner RTX5090 test failed. This candidate needs **new** owner A/B with other games closed *only after* hosted build/test success. Maintain unchanged release, and use E087 supervisor to guarantee anonymous crash ZIP. Candidate has **NOT RUN** on owner RTX5090 at PR creation.

## Dependencies and alternatives
[Upstream #3561](https://github.com/Marvisak/VIctory/pull/3561) is a separate 1D dispatch thread-count guard stacked on [#3426](https://github.com/Marvisak/VIctory/pull/3426), tested on AMD RX6800XT and not blindly integrated here; [upstream #3546](https://github.com/Marvisak/VIctory/pull/3546) large descriptor/shader patch had exact-context mismatches against PR27. Keep E095 fallback and PR31 numeric D3D12 log patch separate until proven compatible. No changes to fork `main` without explicit permission.
