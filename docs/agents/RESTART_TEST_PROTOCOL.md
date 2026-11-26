# Agent restart / interrupted-work rehearsal

Run the **synthetic, offline** exercise from the repository root:

```bash
bash scripts/check-agent-docs.sh
bash scripts/test-agent-restarts.sh
```

The same two checks run in the `agent-docs` GitHub Actions job for pull requests and changes to `main`. The restart test creates a temporary **local bare Git remote**, seeds it from the exact checked-out commit (`git archive HEAD`), and launches workers as separate Bash processes with cleared inherited environments and independent clone directories. It does not push or write to the real GitHub repository, change real branches, run the game, or access a GPU.

## Scenarios with real assertions

1. A cold-started process successfully reads the required onboarding files and verifies a pinned Git baseline.
2. A stale `CLAIMED` entry without a live branch is not accepted as an exclusive lock.
3. Session A creates a task-specific branch, commits a `NOT_RUN` checkpoint and pushes it to the **temporary** remote.
4. A different process is deliberately killed with **SIGKILL (exit 137)** after writing uncommitted state. That state cannot become the shared handoff.
5. A new process from a fresh clone resumes the same task from its committed checkpoint without access to the previous process's memory.
6. Two worker clones start at the same branch SHA; the second worker's stale non-fast-forward push must be rejected, leaving the first worker's commit untouched.
7. A missing `AGENTS.md` causes bootstrap to fail closed.
8. An outside PR note containing malicious instructions is left inert by the synthetic parser; it is never executed.
9. After the temporary `main` moves, an earlier session refuses to trust its stale pinned base SHA.

Each positive and negative assertion prints `PASS:`; a failure exits nonzero so GitHub Actions reports failure. The simulator runs solely against ephemeral dummy tasks, local Git clones, and source-controlled onboarding documents.

## What this does **not** prove

This is a **process / Git protocol test, not an AI-agent behavior test**. Shell processes are not newly instantiated LLMs; the checks cannot demonstrate that a model will obey instructions, refuse prompt injections, select correct fixes or produce accurate reasoning. Git's non-fast-forward rejection is not proof that GitHub branch protection is enabled, and a simulated local remote does not reproduce GitHub's PR review workflow or permission settings. The test cannot validate real RTX 5090 rendering, shader behavior or gameplay. Independent, permissioned AI-worker review remains necessary for those claims.

A future human/agent acceptance drill should start two truly separate chat/agent sessions with only the repository URL and [new-session prompt](NEW_SESSION_PROMPT.md), deliberately interrupt one midway through a scoped draft PR, then ask the other to reconstruct the task using live GitHub only. Record exact PR/commit/CI links and whether the second agent correctly distinguishes `NOT_RUN` from actual hardware evidence. **Do not imply this human/AI drill occurred because the synthetic CI passed.**
