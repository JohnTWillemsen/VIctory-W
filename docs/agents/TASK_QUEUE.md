# Active task queue — NVIDIA-based VIctory-W

**Dated:** 2026-11-27 America/Phoenix. **Live GitHub PR heads/branches override statuses.** The old ~112 KB E001–E125 task ledger from the AMD-source era is preserved at the immutable [pre-audit main commit](https://github.com/JohnTWillemsen/VIctory-W/blob/6b6bdf4219fc31eb35a8411e1b76fa9c03b2b1b7/docs/agents/TASK_QUEUE.md); this new file intentionally lists **only live source priorities**. Historical evidence is additionally preserved append-only in [EVIDENCE_LOG](EVIDENCE_LOG.md) and [DECISIONS](DECISIONS.md).

| Task | Status at dated checkpoint | Acceptance and next action |
| --- | --- | --- |
| **VW-072 — Full NVIDIA source replacement** | **COMPLETE, not merely a proposal.** Merged PR37/PR38; NVIDIA v8 is `main` `6b6bdf4`, old source archived. | Verify current main SHA on every session; no reimport. |
| **VW-073 — RTX5090 first actual playable-world acceptance** | **P0 / HARDWARE NOT_RUN.** E127 report PowerShell fake-log fixture PASS, NVIDIA source release compilation PASS. | Owner-consented run via `scripts/research/owner-nvidia-session.ps1` from source-verified main and one anonymous ZIP. Confirm actual selected host RTX5090, rendered 3D `World`, controls `Yes`, and crash/status fields. Preserve raw logs locally. |
| **VW-074 — Inherited NVIDIA D3D12 GPU synthetic failures** | **P1 / REPRODUCED RED** on Windows Actions. Tests: `indirect::tests::host_list_budget_starts_empty_at_each_submission`, `indirect::tests::warp_batch_charges_every_execution`, `pipeline::host::tests::depth_bounds_pipeline_loads_and_filters_draws`. | Identify test adapter/device capabilities (WARP vs GPU), distinguish test expectation vs source bug, develop bounded regression/repair on branch, don't mask red by disabling tests. |
| **VW-075 — Inherited strict upstream Clippy warnings** | **P2 / RED** independently of runtime. | Fix justified style/test warnings on an isolated branch, no global suppressions or claims of playability. |
| **VW-076 — Maintain anti-stale continuity handoff** | **COMPLETE (E129):** canonical docs and fresh-clone smoke test merged through PR39; main continuity check green at that checkpoint. | Keep [HANDOFF](HANDOFF.md), CURRENT_STATE, LATEST_CHECKPOINT, NEW_SESSION_PROMPT and evidence aligned. Automated CI check must PASS. |

| **VW-077 — Isolate owner's new NVIDIA Windows workspace (E130)** | **Documentation and report-root correction under review.** Owner selected `C:\VIctory-NVIDIA` and `C:\VIctory-NVIDIA-Tests` while preserving old `C:\VIctory-W`. | Verify [LOCAL_WORKSPACE.md](LOCAL_WORKSPACE.md), E127 new report root, full prompt, CI, and first local clone output when owner provides it. Remote GitHub cannot confirm Windows folder creation. |

**Task ownership:** Never infer a task is unclaimed solely from this dated Markdown. Query open PRs, branch tips, recent main commits and Actions first. The original source and old experimental PRs are preserved for research but are **not** active Nvidia runtime changes. Use one focused branch/PR per task. No commits to `main` without owner authorization and exact-head review.

**Privacy:** No title executable, proprietary data, raw GPU logs, screenshots, identifying file paths or dumps in this PUBLIC repo. For owner tests accept only the fixed-schema E127 anonymous summary ZIP.
