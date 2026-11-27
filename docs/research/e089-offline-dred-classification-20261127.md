# E089 — Offline DRED/Direct3D crash marker analysis from E087

## Why / new evidence
Owner's real [E087](https://github.com/JohnTWillemsen/VIctory-W/pull/22) private anonymous ZIP had `status=TITLE_EXITED`, `outcome=EXIT_NONZERO_OR_CRASH`, signed exit `-2005270523` = `0x887A0005 / DXGI_ERROR_DEVICE_REMOVED`, elapsed 63s, 316502 captured private log lines, 2 lines containing `0x887A0006`, 4 containing `device removed`, 1 slow host submission line, 10 containing DRED/breadcrumb/page fault and 2 shader warning lines. **Do not conflate marker line counts with unique GPU incidents, or the old E085 black-screen user observation with E087 visuals.** E087 synthetic and repo CI passed; this real GPU result confirms post-crash report finalization, not playability.

Raw E087 private logs remain on owner's PC. Ten marker lines do **not** prove DRED supplied a command breadcrumb. A new game launch is not warranted merely to inspect existing logs.

## E089 implementation and boundaries
`scripts/research/owner-e089-offline-dred-classifier.ps1` reads **only** the existing E087 `PRIVATE-logs-do-not-upload\title-stdout-private.txt` and `title-stderr-private.txt`, with `upload-only\E087-anonymous-status.txt` format check and an exact `E087-supervised-YYYYMMDD-HHMMSS-<hex>` folder-name gate. It does **not** run the title, call the network or access game assets, scripts, shader binaries, cache or saves.

It streams the already-written logs locally with bounded tail retention (512 lines). The report `E089-offline-dred-counts.zip` holds one fixed-schema `E089-anonymous-dred-counts.txt` of integer counts/operation indices and controlled constant labels only. Fields include maximum reported slow submission ms/list count, line counts of device-removed/device-hung codes, DRED no-breadcrumb markers, auto-breadcrumbs, page faults, stopped-command index/total/op-code when present, shader translation/pipeline failures, GPU descriptor warnings and counts of several marker categories in the last 512 logged lines. It never copies raw log lines, shader hashes, addresses, paths, exception messages, or screenshots. It uses atomic same-volume file replacement with backups; repeatable over unchanged logs. Only the derived ZIP is for private upload to ChatGPT. **Do not post owner private logs or ZIP to public GitHub.** Source and synthetic fixtures are public; no game content is added.

Caveats: `tail_512_*` is the final 512 lines of the concatenated first stdout then stderr files, not necessarily chronological interleaving across both streams. Counts may double-count the same GPU incident described in both channels. A DRED marker count does not prove a breadcrumb exists or identify the faulting shader. A zero for `dred_last_stopped_op_code` is the absence of a parsed op-code (or literal zero), not proof the GPU reached operation zero. This is offline research instrumentation, not renderer implementation.

## Synthetic Windows 5.1 gate
`scripts/research/test-e089-offline-dred-classifier.ps1` creates artificial E087-shaped logs with fake paths, addresses, hashes and GPU messages. It verifies:

1. Correct parsed synthetic slow submission, DRED stopped command/operation, failure markers and reduced fixed-key schema.
2. No fake secret, path, address, shader hash or raw text in the ZIP.
3. Repeatable, atomic output on the same input without title launch.
4. Fail closed on invalid run directory and missing private logs.

`.github/workflows/e089-offline-dred-classifier.yml` runs these on real hosted Windows PowerShell 5.1. Owner test **NOT_RUN** until the generated ZIP arrives; do not infer any screenshot/audio/image state.

## Next action after green CI
Owner runs the pinned E089 offline classifier on the already-ended E087 run folder and uploads **only** `E089-offline-dred-counts.zip`. Do not run GTA again. If E089 shows no usable breadcrumb, the next decision should follow true source-level DRED/command diagnostic code review or staged host fix, not random pipeline skipping.
