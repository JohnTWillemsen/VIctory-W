# Roadmap — acceptance gates rather than speculative deadlines

Priority: **correct rendering → stability → usable frame time → broader GPU coverage**. Branches should serve Marvisak upstream and avoid needless divergence.

| Phase | What qualifies as progress | Current status at initial snapshot |
| --- | --- | --- |
| 0. Project governance | Agent rules/index/handoff, PR template, documentation integrity and restart simulation on isolated branch | PR #1 OPEN/DRAFT; synthetic [restart CI](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45867868772) passed on pinned head; **owner merge approval and latest-head CI still required** |
| 1. Repeatable source baseline | Exact `main` SHA, Windows locked workspace tests/Clippy, asset policy, release and diagnostics compilation linked to an exact run | NOT YET VERIFIED for new-fork candidate |
| 2. RTX 5090 baseline | Native GPU and driver identified, first menu/world/visual checklist, save/scene/settings, same-executable hash recorded, crash signature if any | NOT_RUN |
| 3. Isolated compatibility work | One concrete bug, known-good baseline, synthetic regression, focused PR with provenance, negative case and rollback | PLANNED |
| 4. Graphics parity | Same-scene screenshots inspected *locally*, correct world geometry, character skin/hair, streaming, water, UI, light/shadow | PLANNED; missing full ray-traced lighting known upstream |
| 5. Stability | Repeatable scene/mission progression, no device removal or omitted essential draws, careful multi-run comparison | PLANNED |
| 6. Performance | Median and tail frame time on comparable world frames; speedup without lost draws or degraded image | PLANNED |
| 7. Upstream contribution | Small GPL-compatible, independently reviewed PR to Marvisak with test logs, source attribution and limitations | PLANNED |

Do not treat these phase headings as proof of implementation. Use [TESTING](TESTING.md) for qualifying evidence, [CURRENT_STATE](CURRENT_STATE.md) for what is actually true today and [DECISIONS](DECISIONS.md) for priorities/changes.

**Scope guard:** A brand-new loader, an entirely separate emulator, mass-importing other forks, unrequested feature work, changing base branch or enabling risky experimental defaults requires an explicit owner decision.
