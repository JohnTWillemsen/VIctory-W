# Paste-ready new-session prompt — NVIDIA-based VIctory-W

The paragraph below is the **complete message** to paste into a new session. It contains no fixed commit SHA: GitHub live main and its docs are authoritative.

> Continue development as lead engineer and GitHub orchestrator for my **VIctory-W NVIDIA-based Xbox-to-Windows compatibility project**: https://github.com/JohnTWillemsen/VIctory-W.
>
> **GitHub is the development source of truth.** Verify the live `main` SHA, recent commits, open PRs, CI jobs, and relevant upstream NVIDIA changes. Read `AGENTS.md`, `docs/agents/HANDOFF.md`, and **`docs/agents/LOCAL_WORKSPACE.md`**, then follow their links to current state, active tasks, evidence, decisions and the E127 test/upload protocol. Correct contradictions only when independently verified.
>
> **Repository vs local folders:** Keep using the existing GitHub repo `JohnTWillemsen/VIctory-W` with the already-merged NVIDIA-based source. It is **not** a newly created GitHub repo; the **fresh, separate Windows clone** belongs at `C:\VIctory-NVIDIA`. All new private test sessions and anonymous report ZIPs belong under `C:\VIctory-NVIDIA-Tests`; pass that as `-ReportRoot` even though the script fallback should also be updated. The old local checkout `C:\VIctory-W` must remain untouched. **Leave game files in their existing location.** Verify local folders/remotes before assuming they exist; do not move old binaries, experiment configurations or caches into the new clone.
>
> **Continue from the latest *verified* checkpoint.** Do not restart development, revive AMD/Marvisak-based experimental branches, assume gameplay works, repeat completed GPU tests, or blindly merge old fixes. Aim for a correctly rendered and controllable 3D world on my RTX 5090, then graphics correctness and stability. Separate Windows release build, strict Clippy, synthetic/WARP GPU failures, and actual owner-observed 5090 World+Controls evidence.
>
> Before the first E127 owner GPU launch, verify NVIDIA `play::prepare` still preserves `VICTORY_HOME` and `VICTORY_ADAPTER`. The E131 fix has merged into main, as has E133's bounded-head host-adapter evidence fix; verify both against live GitHub and CI before running E127. Do not request a hardware run using a pre-fix binary.
>
> Work independently in isolated GitHub branches and PRs; review exact-head CI, fix actual outstanding issues, and update canonical handoff/evidence/decisions at significant milestones. No unapproved force-pushes or experimental runtime merges. Keep raw logs/game data, shaders, crash dumps, private paths and title assets local; for a hardware test request only **one E127 anonymous report ZIP** after explicit `PLAY` confirmation. Only ask me for a verified download or PowerShell command when my actual PC is required.

The handoff is stored **in GitHub**, not in an external document, ChatGPT chat transcript or local artifact. A new session fetches live source/evidence and discovers any later changes. The former longer prompts are in Git history only.

## E139 owner RTX5090 gameplay milestone — new verified information, 2026-11-27 AZ

The owner has now completed a source-matched NVIDIA-v8 E127 real RTX5090 test on `main` `8caccae47243cad361038bab4d4d4025f90ccc82`; initial E127 ZIP `visual=Unknown`, `controls=Yes`, RTX5090 host selected, clean exit and no recognized GPU fault markers. The owner **subsequently and explicitly confirmed seeing a rendered 3D interior and moving the character through it**. Record this as initial **indoor 3D World+Controls PASS by owner confirmation**, while preserving historical ZIP field `Unknown`. This is NOT evidence of broad playable game/open world, graphics fidelity, other areas or sustained stability. E138 [PR45](https://github.com/JohnTWillemsen/VIctory-W/pull/45) fixes an independent ~7h inflated E127 elapsed field; verify whether merged and whether the fixture passed. Owner local `C:\\VIctory-NVIDIA` clone and `C:\\VIctory-NVIDIA-Tests` root are also verified created by E136/E137; don't ask to clone again. Use live main and canonical handoff, then prioritize wider scene progress or correctness without repeating already established interior result.
