# NVIDIA foundation source — E126 migration

- **Repository:** https://github.com/trustno1-coder/VIctory-NVIDIA
- **Exact source release:** v2026.11.27.8
- **Pinned upstream commit:** `64d4931b3dd90305134512b805fc98f04119fb6e`
- **Source lineage:** foxhound and Marvisak/VIctory, as credited in upstream README.
- **Original VIctory-W main / rollback:** `63bcca43c6a00a758510398fa43096ce7e4f7df0` and `archive/pre-nvidia-foundation-20261127`.
- **Agent continuity:** `AGENTS.md` and `docs/agents/**` brought in unchanged from `docs/agent-continuity-system-20261126`; earlier E001–E125 observations still historical; previous E108/E109/E121 candidates are **not** treated as fixes in this base.
- **Historical source preservation:** pre-migration main and all old draft PR refs remain; no force-push or deletion.
- **Licensing:** GPL-3.0-or-later upstream. Their `docs/asset-policy.md` describes one exceptional `crates/victory-formats/src/bcpack-tables.bin` constant format table not covered by the main license. Preserve provenance and review rights before redistribution.
- **Build status:** importing source into GitHub is not a passing build, functional title test, or playable RTX5090 confirmation.
- **Game artifacts:** never add game executable, archives, title shaders, private logs, screenshots or user-identifiable paths to this public repository.
- **First test design:** follow upstream's own built-in launcher defaults and selected host D3D12 GPU; record actual vendor/name, intro, 3D world, controls, exit vs expected first-run restart. Keep raw diagnostic logs local, export one allowlisted ZIP per run.
