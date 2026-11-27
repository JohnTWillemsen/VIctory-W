# E-062 — Controlled RTX 5090 title-visual A/B (owner opt-in only)

**Status:** code/static-only until the owner explicitly launches each variant; no title was launched by GitHub Actions.

## Why this gate exists

- E-058 E052 physical RTX5090 six-PR baseline: **303 executed synthetic tests pass, 0 failed, 1 ignored**; executable SHA256 `616e3bc91252fd30f5f3b52dc81e0d8b0d6d93e384af3ce1e8b74c65fab3d554`.
- E-061 E060 isolated Belobug #449 normalized D3D12 before/after resource barrier: **311 executed synthetic tests pass, 0 failed, 1 ignored**, with the additional 4 unit tests run twice (focused/full GPU); physical NVIDIA RTX5090 617.42; executable SHA256 `5e378b0e3673059cbbffcee54f0d83cedbde00ff0f40522136022e2dc469c723`. [Hosted E060 CI 45936578198](https://github.com/JohnTWillemsen/VIctory-W/actions/runs/45936578198) all three jobs pass.
- Neither synthetic result proves a rendered scene. The next falsifiable hypothesis is that legalizing the **BEFORE** state in a D3D12 resource barrier prevents NVIDIA debug error ID 523 / `E_INVALIDARG` and allows a previously black/grey world or missing render stage to progress. It might have no visible effect.

## Owner-only side-by-side procedure

The [owner E062 PowerShell script](../../scripts/research/owner-e062-rtx5090-visual-ab.ps1) does **not** download or launch a title automatically. The owner must pass the local `-GameExe` path and independently type **LAUNCH** before each candidate. Only source-generated local VIctory executables with the exact two SHA256 hashes above are accepted.

1. Keep the NVIDIA driver and Windows build unchanged. Close Brawlhalla and GPU-heavy apps. Ensure adequate Windows committed-memory capacity (the upstream project estimates ~33 GB commit for world traversal); consider backing up saves. GPU driver hangs or reset remain possible.
2. Run `-CheckOnly` to verify both known source-generated executable files, NVIDIA RTX5090 and hashes, without title execution. The E052 baseline and E060 candidate are stored in distinct folders from their prior owner harnesses; custom executable paths can be provided with `-BaselineExe`/`-CandidateExe`.
3. For each run separately, type **LAUNCH**. The runner launches `victory.exe run "<local exe>" --execute --console series-x` because the CLI's `run` **without `--execute` only binds without executing title code**. It explicitly disables the WARP override, inherited GPU-based validation and game frame-capture/dump variables; D3D12 debug layer is **off by default** to preserve baseline visual behavior.
4. Inspect the **same menu/intro/first visible scene** for a comparable period with both builds: black/grey/purple vs visible textures, geometry, lights, UI; responsiveness, crash, display-driver reset or command-list failure. Close the first title process manually before proceeding to the second. The runner never auto-kills a title. Describe observations interactively.
5. The runner writes **only a private ZIP** containing manifest, stdout/stderr, short owner observations and result, not a game executable, shaders, caches, screenshots, game files or saves. The owner uploads it **only in ChatGPT**, never GitHub. If screens make differences clearer, owner may separately upload screenshots *privately* in ChatGPT. Do not publish any game-derived logs or artwork to the public repo.
6. If both render identically or D3D12 barriers are still suspect, a **separate explicit owner run** with `-EnableDebugLayer` on *both* cases may show D3D12 error ID 523 and other host validation messages; do not enable costly GPU-based validation until basic debugging is understood.

## Acceptance labels

- **PREFLIGHT_PASS:** known public source-generated binaries verified, hardware RTX5090; no title launched.
- **OWNER_VISUAL_OBSERVED:** exactly which scene and comparative outcome the owner reports, with relevant stdout/stderr reviewed privately; without direct screen evidence, don't infer graphics correctness from logs alone.
- **PERFORMANCE_UNKNOWN:** screenshots, build hashes and initial loading are not FPS benchmarks. Do not claim performance improvement from synthetic tests or qualitative visuals.
- **REGRESSION:** if candidate crashes earlier than baseline, preserve logs and never promote/merge until investigated.
- **UNPROVEN:** no actual title execution, no comparable scene, missing one variant, or incomplete/unsafe test.

## Boundaries

Neither this research doc nor GitHub Actions touches the private title. All game material stays on the user's machine or within private chat attachments; do not put actual game paths, shader hashes derived from title content, raw title logs, user names or title screenshots in GitHub. Experimental PRs remain draft and `main` is not changed. This protocol is **not** a recommendation to distribute, upload, or obtain a proprietary game.
