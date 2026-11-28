# E155 — Integrate isolated E154 depth-bounds WARP regression with E152 tests

Date: 2026-11-27 America/Phoenix. Base: NVIDIA `main` at `ea186566a868430a51e416d4c94695f6aff3fce1`. Integrated into [draft PR56](https://github.com/JohnTWillemsen/VIctory-W/pull/56) **only under a test module and workflow**, with no production renderer modification.

## Why the third inherited test failed

[PR56 E127 full Windows CI 46101133726](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46101133726) improved the original 433 pass / 3 fail / 36 ignored to **435 pass / 1 fail / 36 ignored**. The last failing test was `pipeline::host::tests::depth_bounds_pipeline_loads_and_filters_draws`: it drew a color pixel (255) when the stored depth 0.5 should have failed the specified bounds [0.6, 1.0]. Crucially, WARP reported support for D3D12 depth bounds; the test did not use its unsupported-feature skip.

The original fixture enabled `DepthBoundsTestEnable` but set `DepthEnable=false`. The Microsoft [D3D12 depth bounds specification](https://microsoft.github.io/DirectX-Specs/d3d/DepthBoundsTest.html) says bounds compare the **stored** depth value, independently of the pixel shader's output. The [OMSetDepthBounds reference](https://learn.microsoft.com/en-us/windows/win32/api/d3d12/nf-d3d12-id3d12graphicscommandlist1-omsetdepthbounds) describes dynamic bounds and driver support, but does not by itself prove identical behavior across WARP and hardware when the ordinary depth test is disabled.

## E154 controlled one-variable diagnostic

[Draft PR58](https://github.com/JohnTWillemsen/VIctory-W/pull/58), based on PR56's tested snapshot `5e02e5010680ce5fa8f4b6a8a6c25da51ec0b20d`, changed only the fixture `DepthEnable=false` to `true`. It **kept** `DepthFunc=ALWAYS`, `DepthWriteMask=ZERO`, `DepthBoundsTestEnable=true`, two positive/negative rendered-pixel assertions, pipeline-library round trip and dynamic-list replay. An ordinary depth comparison thus cannot reject the draw, and any negative pixel result is attributable to the depth-bounds rule.

[E154 exact-head Windows WARP run 46103790287](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46103790287) completed **1 passed, 0 failed, 0 ignored** with explicit `E154_WARP_DEPTH_BOUNDS_WITH_DEPTH_ENABLED_PASS=true`, and did not print any unsupported-feature or DXC skip message. This is an actual WARP readback result; it is **NOT** RTX5090 gameplay or a claim that `DepthEnable=false` is invalid per API.

## E155 combined acceptance

The same targeted fixture adjustment is staged in PR56's `crates/victory-gpu/src/pipeline/host.rs`, beneath `#[cfg(test)]`. The E152 exact-source Windows workflow now runs **both budget tests in REST 0 and 1**, plus the depth-bounds actual-pixel test. The full E127 Windows GPU suite must separately execute unmodified in its entirety. The PR remains **DRAFT** until the new exact-head focused workflow, full GPU synthetic results, source-only Windows release, privacy fixture and handoff integrity are checked; strict Clippy is an independent known inherited failure. Do not mark whole CI green unless it really passes.

Runtime effects: **none**. Original pinned NVIDIA runtime main continues to have an owner-confirmed, controllable 3D interior (E139); PR50's purported 29.1 FPS candidate remains visual/input unconfirmed. No title assets, private logs, shaders, binary dumps or RTX5090 session were used or uploaded. Keep [PR57](https://github.com/JohnTWillemsen/VIctory-W/pull/57) opt-in DXGI presentation completely separate from test-only PR56.

Rollback: close PR56 or revert the test-only fixture change if later feature-specific Windows tests contradict it. Preserve original red results as historical evidence rather than editing the earlier E127 rows.
