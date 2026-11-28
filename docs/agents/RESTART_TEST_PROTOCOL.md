# Agent continuity / cold restart acceptance — E129

**Current, actually installed test:**

```bash
python scripts/check-continuity.py --smoke-clone
```

Source: [scripts/check-continuity.py](../../scripts/check-continuity.py). GitHub Actions: [E129 continuity workflow](../../.github/workflows/e129-continuity.yml), which runs on pull requests and `main`. Both are **source-only**, using Python's standard library and a temporary local Git clone.

## Assertions that actually run

1. Required source and governance files exist; exact NVIDIA v8 upstream source pin and original-source archive are present and consistent in canonical handoff, current state and latest checkpoint.
2. AGENTS and the short new-session prompt point to the canonical handoff and demand **live** source verification. The prompt cannot embed a 40-character commit SHA that ages into a stale requirement.
3. Canonical handoff files have strict size limits, preventing the former 70–170 KB stack of contradictory status paragraphs. The old text remains in immutable Git history and the append-only evidence/decision registers.
4. E-series evidence IDs are sequential and not truncated below the pre-migration E128 baseline. Source build, synthetic test, actual GPU gameplay and privacy-safe one-ZIP/report milestones remain separately stated.
5. A **new throwaway local Git clone** contains the same committed HEAD and successfully reads the required handoff without any previous process memory, files or user HOME. Deleting the canonical handoff *in that disposable clone* must make verification fail closed.
6. Never read proprietary game data, raw title logs or owner-specific directories and never launch the game, GPU, renderer, SDKs or other external processes for the acceptance script.

## Boundaries and honesty

This replaces an **obsolete description** of shell scripts `scripts/check-agent-docs.sh` and `scripts/test-agent-restarts.sh`: those scripts were **not carried into the full NVIDIA source migration** and must not be described as active. The old text/test claims remain in Git history for provenance. The current smoke test also does not simulate competing remote pushes or SIGKILL worker crashes; do not claim it does.

CI cannot ensure an independently launched language model will interpret old evidence correctly or always follow instructions. It cannot verify the owner's RTX5090 hardware, game saves, driver, graphics, controller or actual playability. For those use the separate consent-gated E127 protocol with actual observed World/Controls and an anonymous ZIP.

If this test fails, **fix the documents or test**; do not bypass assertions, mask conflicts, invent a green run or ask the owner for another GPU crash experiment.
