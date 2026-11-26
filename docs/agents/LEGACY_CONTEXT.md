# Previous fork — reference only, never silently merge

This is a **new, clean fork of Marvisak's VIctory**. The earlier owner-maintained repository is **different**:

- Old project: https://github.com/JohnTWillemsen/victory-fork
- Old project historical agent rules: https://github.com/JohnTWillemsen/victory-fork/blob/main/AGENTS.md
- Old living handoff (some sections stale): https://github.com/JohnTWillemsen/victory-fork/blob/integration/rtx5090-fxceless-20261125-reviewed/docs/RTX5090_HANDOFF.md
- Old user-specific first-run matrix: https://github.com/JohnTWillemsen/victory-fork/blob/integration/rtx5090-fxceless-20261125-reviewed/docs/RTX5090_PREHOME_TEST_MATRIX.md
- Old combined experimental integration PR: https://github.com/JohnTWillemsen/victory-fork/pull/47
- Old combined integration SHA reported and live-inspected in prior work: `c924825e7d9b63aeae80996f92e0adf2ab459923`
- Old CI run reported successful: https://github.com/JohnTWillemsen/victory-fork/actions/runs/45690341369 ; old WARP run: https://github.com/JohnTWillemsen/victory-fork/actions/runs/45690341525

At the time of previous handoff, the **old fork** had separate Windows build and synthetic GPU evidence, but **no verified native Windows gameplay on the owner's RTX 5090**. These are **not** VIctory-W CI results. Past documentation can contain outdated branches, deferred tests, conflicting conclusions or stale upstream links.

**Reuse protocol:** fetch the specific old SHA and patch, identify author/source/license, compare with current VIctory-W and Marvisak main, reproduce source-only regressions, stage one dedicated PR, test on actual target hardware before any gameplay claim. Never replace new `main` with the old integration branch or assume previous experiments failed or passed on this new base.
