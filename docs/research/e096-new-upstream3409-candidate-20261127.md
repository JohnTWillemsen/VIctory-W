# E096 — compare newest gameplay-tested upstream PR3409 against our previous failed E085

Date: 2026-11-27 (America/Phoenix). This is an *alternative standalone upstream candidate*, not a six-PR merge and not `main`.

## Exact evidence
- Last owner E085 NVIDIA RTX 5090 #3409 source was `1e25b230d6572f08e718a1df31a619bb43070481` and showed a black screen with later-scene audio, followed by device hang. E087 on same executable crashed at 63s `0x887A0005`. Owner did NOT test any newer #3409 code.
- Live upstream [PR3409](https://github.com/Marvisak/VIctory/pull/3409) now `965d93823587932e8f40b152b8d4faab5f7a9c85`, **66 commits ahead of prior head**, GitHub exact-head [CI 46032183866](https://github.com/Marvisak/VIctory/actions/runs/46032183866) SUCCESS. Author describes 53 PRs added in tested batches, with 3x 300s same-machine title runs after a device-removal root cause, >10k draws per frame in the prison yard and visible world. **UPSTREAM_REPORTED ONLY**, including known intermittent 60-second black cutscene 120-180s in about one run in three; no verification on owner's RTX5090.
- The aggregate contains exact raw-view alignment correction #3540 and once-only heap warning #2634, as well as held-key #3392, but it does *not* contain the owner's separate E045 six-PR #439 Wave64/BVH stack. These variants should remain separate, not merged blindly.
- Source risk: #3409 is not cleanly proven equal to our validated combined renderer. Do not infer it repairs our E075 seven missing BVH pipelines, makes FPS faster, or renders correctly on RTX5090.
- This E096 workflow clones only public source, validates upstream head precisely and ancestry to old E085 pin, compiles all-targets, Clippy default+features, workspace tests, release diagnostics. If and only if all pass, uploads a *public-source-only* `victory.exe` plus SHA256 manifest with title/owner test NOT_RUN.
- All tests performed in hosted Windows are software compilation/unit tests, not physical RTX5090 or title gameplay.
- If source head changes, script refuses; no automatic new upstream code, no proprietary files, no force pushes or main merge. Close draft PR to rollback. Owner intervention only after pinned artifact passes and a safe opt-in supervised title A/B is ready.

Possible future owner outcome classification: correct 3D scene + movement + 300s stable vs black/audio vs device removed vs shader refusals; user observations and GPU timing must be provided separately.
