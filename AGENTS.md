# VIctory-W — mandatory instructions for coding agents

This file is the **entry point** for every ChatGPT, Codex, Copilot, Claude, Cursor or other automated contributor. The project is [JohnTWillemsen/VIctory-W](https://github.com/JohnTWillemsen/VIctory-W), a clean fork of [Marvisak/VIctory](https://github.com/Marvisak/VIctory). **Read this before proposing, changing or merging anything.**

## Start here (in order)

1. [Agent documentation index](docs/agents/README.md).
2. [CURRENT_STATE](docs/agents/CURRENT_STATE.md) — **dated snapshot, not a substitute for live repository verification**.
3. [WORKFLOW](docs/agents/WORKFLOW.md) and [RESEARCH_PROTOCOL](docs/agents/RESEARCH_PROTOCOL.md).
4. [ROADMAP](docs/agents/ROADMAP.md), [EVIDENCE_LOG](docs/agents/EVIDENCE_LOG.md), [DECISIONS](docs/agents/DECISIONS.md).
5. [Architecture](docs/architecture.md), [asset policy](docs/asset-policy.md), README, current source and relevant tests.

## Mission and boundaries

Develop correct, stable and eventually performant **open-source Xbox Series compatibility** with a focus on the user's Windows 11 / NVIDIA RTX 5090 testing. **Contribute broadly applicable corrections to Marvisak's upstream**. Use other forks as potential sources of ideas, not as unquestioned authorities. Correctness and intact rendering come before stability, and stability before raw FPS. This is not a sanctioned native PC port or a claim of playability.

The new repository is **NOT** the old `JohnTWillemsen/victory-fork`. Experimental branches, commits and validation in the old repository have **not been imported**. See [LEGACY_CONTEXT](docs/agents/LEGACY_CONTEXT.md) before reusing any previous work.

## Nonnegotiable rules

- **Verify before asserting.** At session start read live repository, exact default-branch HEAD, open PRs/branches, relevant upstream commits/PRs/issues and their disposition, and latest CI. If unavailable, write **UNKNOWN / NOT VERIFIED**. Do not invent branch names, issue numbers, command results, performance, code locations or patches.
- **Evidence tags are mandatory:** `SOURCE_READ`, `CODE_REVIEWED`, `CI_PASS`, `UNIT_PASS`, `WARP_PASS`, `GPU_PASS`, `GAMEPLAY_OBSERVED`, `UPSTREAM_REPORTED`, `NOT_RUN`, `UNKNOWN`. Only claim a tag with a source, exact SHA, environment and limitations. A build/CI result is never a gameplay result.
- **Prove the fix is missing.** Before importing a patch, inspect our actual file/commit and the upstream implementation. Compare behavior and tests; identify duplicates, conflicts, license/provenance and feature flags. A PR title, open issue or fast FPS claim is not proof.
- **Protect `main`.** Work on single-purpose `research/`, `fix/`, `test/`, `docs/` or `experiment/` branches and PRs. **Do not directly commit to `main`, force-push, rewrite history, mass-merge, change default performance switches, or merge a PR without explicit owner authorization and matching checks.** Draft/experimental code stays outside `main`.
- **No game material in Git.** Read [asset policy](docs/asset-policy.md), including its narrow existing BCPack-table exception. Do not commit title executables/DLLs, proprietary assets, derived shaders/dumps, captures/screenshots, saves, private paths or unredacted logs. Synthetic tests are preferred. Keep legally obtained local inputs outside the checkout.
- **Tests are real events.** Never say a test passed unless you ran it or inspected an exact-head completed run. Distinguish an ordinary Windows CI runner, WARP software adapter, physical NVIDIA GPU, and actual title execution.
- **Preserve attribution and GPL obligations.** Record original URL, author, commit and license when adapting outside work. Do not assume similarly named repositories share compatible code licenses.
- **Close the loop.** After meaningful work, update [CURRENT_STATE](docs/agents/CURRENT_STATE.md), [EVIDENCE_LOG](docs/agents/EVIDENCE_LOG.md) when tests ran, and [DECISIONS](docs/agents/DECISIONS.md) when a direction changed. A PR must say what is done, untested, blocked and next.
- **Stop safely on contradictions.** If current GitHub state, code, docs and remembered context disagree, treat code and exact run evidence as authoritative and flag the conflict. Do not silently reconcile it by guessing.

## Required deliverable for every coding task

A focused PR with precise base/head SHAs, original source of the idea, changed files, implementation rationale, tests and results/limitations, risk and rollback, and what someone must test on real RTX 5090 hardware. Use [the PR template](.github/pull_request_template.md). **Never report success solely because a PR was opened.**
