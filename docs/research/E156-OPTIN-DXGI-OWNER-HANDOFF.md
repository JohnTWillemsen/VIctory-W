# E156 — Safe opt-in DXGI owner A/B reporting and launch handoff

Date: 2026-11-27 America/Phoenix; starts from NVIDIA `JohnTWillemsen/VIctory-W` `main` `ea186566a868430a51e416d4c94695f6aff3fce1` without modifying runtime binaries. This is a **source-only, game-free test harness change**, not gameplay evidence.

## Why necessary

Draft [PR57](https://github.com/JohnTWillemsen/VIctory-W/pull/57) adds optional `VICTORY_TEARING=1` to request DXGI immediate presentation, with the default **OFF**. The prior E127 harness invoked `victory.exe play <title>` and offered no way to pass that switch. Reusing it unchanged would have tested the default path and falsely labeled a result as "tearing ON".

The runtime's `play::prepare` starts with a cold isolated `VICTORY_HOME`, may perform an automatic one-time warm-up restart, and deliberately discards arbitrary `--set` overrides across that restart. PR57's follow-up source-only [E156 runtime patch](https://github.com/JohnTWillemsen/VIctory-W/commit/7a391de346ec2db455d472a5f7f6edee44b60d04) arranges for **only** the literal `VICTORY_TEARING=1` flag to survive restarts. **Do not run hardware A/B until that patched runtime has exact-head source build and regression success.**

## Test-harness modifications

The existing E127 `owner-nvidia-session.ps1` and E145 `owner-nvidia-candidate-ab.ps1` gain a strictly validated `-Tearing 0|1` parameter, default `0`. E145 passes it to E127 only after exact GitHub head, source-built executable SHA-256, single title executable and private report-root checks. E127 requests literal `PLAY` before launch, then runs one of two **constant**, allowlisted argv paths:

- default: `victory.exe play <local-exe>` (no tearing flag);
- opt-in: `victory.exe play <local-exe> --set VICTORY_TEARING=1`.

E127's anonymous one-member fixed-field report now adds **only** `dxgi_tearing_requested=ON|OFF` from an enum in the private session manifest. It does not include arbitrary user input, launch command, private path, actual title data, game assets, dumps or shader hashes. This field is explicitly **requested** mode; it does NOT assert that the Windows driver or Streamline accepted a tearing swap chain. The runtime checks device support and can fall back to ordinary presentation. Owner's World/Controls answer is independently required.

The E127 `SelfTest` creates synthetic logs under the temporary folder and validates both OFF and ON output ZIPs and privacy, without game launch. E145 `SelfTest` verifies exact source and SHA checks on synthetic non-executable bytes. E156 Windows CI checks exact Git HEAD, PowerShell syntax, and invokes both self-tests using Windows PowerShell 5.1; it never launches the title or downloads the owner's game.

## Hardware acceptance, once eligible

Require PR57 final release build and PR59 E156 synthetic provenance/dual-mode tests to pass, exact SHA match on downloaded artifact and existing clean main checkout `C:\\VIctory-NVIDIA`. Owner runs from ordinary **non-admin PowerShell**, saves backed up, reports rooted `C:\\VIctory-NVIDIA-Tests`, and types `PLAY` only after understanding the GPU-crash/reboot risk. Compare the same interior, matching settings/cache state where practical, and upload only `E127-anonymous-summary.zip` and `E141-anonymous-perf-summary.zip`; never private logs or assets. **One run is a screening check**, not matched-scene proof or source-merge authorization.

Do not give an owner GPU test command until PR57 source build and E156 tests are confirmed and source provenance is rechecked. Existing PR50 candidate visual and controls remain **Unknown**, and owner has not confirmed that candidate's 3D rendering.
