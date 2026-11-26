# Architecture quick map (source path index)

The authoritative system diagram and design notes are [../architecture.md](../architecture.md). Paths below were verified against the original clean Marvisak fork on 2026-11-26; inspect the current source before editing.

| Concern | Source / start with |
| --- | --- |
| CLI and run/inspect/translate commands | `apps/victory`; `README.md` commands |
| Native executable mapping, imports and TLS | `crates/victory-loader`, `crates/victory-pe` |
| Console system APIs, storage and controller input | `crates/victory-hle` |
| GPU command submission, descriptors, residency and textures | `crates/victory-gpu` |
| RDNA2 machine shader parsing/IR/structurization → DXIL | `crates/victory-shader` |
| Texture layouts, BCPack and audio | `crates/victory-formats` |
| Converted caches and game-specific hooks | `crates/victory-pipeline`, `crates/victory-game` |
| App config and asset safeguards | `crates/victory-core`, `xtask/src/policy.rs`, `docs/asset-policy.md` |
| Windows checks | `.github/workflows/ci.yml`; `rust-toolchain.toml` |
| Agent process and handoffs | `AGENTS.md`, `docs/agents/`, `.github/pull_request_template.md` |

**When debugging:** follow the failing call/data path from source and add a synthetic regression near the real component. Do not assume a PR fix mentioned in a README is present in this commit. Don't quote offsets, function names, device behavior or tests without checking the current implementation.
