# E154 — WARP depth bounds diagnostic: depth disabled versus enabled

Base: draft [PR56](https://github.com/JohnTWillemsen/VIctory-W/pull/56), exact SHA `5e02e5010680ce5fa8f4b6a8a6c25da51ec0b20d` on 2026-11-27 America/Phoenix. The original NVIDIA main was `ea186566a868430a51e416d4c94695f6aff3fce1`. **Test-only experiment.**

## Observed failure

PR56 [E127 Windows full suite 46101133726](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/46101133726) passed 435 GPU cases and failed exactly one: `pipeline::host::tests::depth_bounds_pipeline_loads_and_filters_draws`. Render-target first byte was 255, expected 0 for a stored depth of 0.5 with exclusion bounds [0.6,1.0]. This has been present since NVIDIA import and predates PR56. PR56's source-only release and E127 fixed anonymous report fixture passed. **Do not relabel the full suite green.**

The test checked `host.depth_bounds()` (via `D3D12_FEATURE_D3D12_OPTIONS2`) and WARP reported support; it did not take the explicit unsupported skip path. `draw::depth_bounds` uses `ID3D12GraphicsCommandList1::OMSetDepthBounds` and `GraphicsState::replay` reapplies it after a host-list cut. The test originally used `DepthEnable=false` and `DepthBoundsTestEnable=true`. The Microsoft [D3D12 Depth Bounds specification](https://microsoft.github.io/DirectX-Specs/d3d/DepthBoundsTest.html) describes depth bounds as a separate PSO toggle and tests bound depth values but does not establish how this particular CI WARP binary behaves for a disabled ordinary depth comparison.

## Single controlled diagnostic

Change ONLY that test fixture to `DepthEnable=true`, while **keeping** `DepthFunc=ALWAYS`, `DepthWriteMask=ZERO`, `DepthBoundsTestEnable=true`, two bounds tests, pipeline-library load and replay assertions. The ordinary depth test must pass and cannot mask a failed depth-bounds test; whether WARP now discards is measured by the same render-target pixel. There is **no runtime code change**.

The new E154 Windows job checks exact PR head and runs this exact WARP test with `--nocapture --test-threads=1` without title files. An E154 pass proves the enabled-depth fixture works *on that CI WARP*, not that the original false-depth case was harmless, that drivers on RTX5090 pass, or that in-game rendering is correct. An E154 failure identifies further host pipeline/runtime or test problems; keep both observations rather than disabling the test. Do not merge this diagnostic until the semantic implications are reviewed.

## Safety

E154 PR should target the **PR56 experimental branch**, not `main`, to avoid pretending its inherited E152 fixture changes are part of an independent fix. No 5090 run, executable, title shaders, assets, raw logs or owner files uploaded. Any future source change must separately gate the new runtime behavior and compare scene fidelity and performance. Revert by closing E154 PR.
