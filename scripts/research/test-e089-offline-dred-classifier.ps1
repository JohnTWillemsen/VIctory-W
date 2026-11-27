#Requires -Version 5.1
# E089 synthetic Windows testing: no real title, GPU or proprietary logs.
$ErrorActionPreference = 'Stop'
$Script = (Resolve-Path 'scripts/research/owner-e089-offline-dred-classifier.ps1').ProviderPath
$Tokens=$null
$Errs=$null
[void][Management.Automation.Language.Parser]::ParseFile($Script,[ref]$Tokens,[ref]$Errs)
if ($Errs.Count -ne 0) { throw ('E089 syntax errors: '+($Errs | Out-String)) }
$Code=Get-Content -LiteralPath $Script -Raw
foreach ($Forbidden in @('Start-Process','Invoke-WebRequest','Invoke-RestMethod','victory.exe run')) {
    if ($Code.Contains($Forbidden)) { throw ('E089 unsafe non-offline action present: '+$Forbidden) }
}
$Root=Join-Path $env:RUNNER_TEMP ('E089-synthetic-'+[guid]::NewGuid().ToString('N'))
$Run=Join-Path $Root 'E087-supervised-20261127-015632-f1b10c'
$Private=Join-Path $Run 'PRIVATE-logs-do-not-upload'
$Public=Join-Path $Run 'upload-only'
New-Item -ItemType Directory -Path $Private,$Public -Force | Out-Null
Set-Content -LiteralPath (Join-Path $Public 'E087-anonymous-status.txt') -Encoding ASCII -Value @(
'format=E087-durable-gpu-supervisor-v1',
'status=TITLE_EXITED',
'outcome=EXIT_NONZERO_OR_CRASH'
)
$Secret = 'private-cat-pretend-title-secret-verydistinct'
$EvilHash = 'deadbeefdeadbeef'
@(
'2026-11-27T08:57:00Z WARN victory_gpu::host: slow host submission ms=11654 lists=1 pipelines={"[compute '+$EvilHash+']"}',
'2026-11-27T08:57:01Z ERROR victory_gpu::host: host GPU device removed after a submission of 1 lists; no breadcrumbs 0x887A0004; device removed: 0x887A0006',
'2026-11-27T08:57:02Z INFO DRED stopped at command 514 of 1304 (op 5) in '+$Secret,
'2026-11-27T08:57:03Z INFO DRED page fault 0x148981EF0 '+$EvilHash,
'2026-11-27T08:57:04Z ERROR D3D12 debug layer: ERROR descriptor slot null',
'2026-11-27T08:57:05Z WARN shader does not translate '+$EvilHash,
'2026-11-27T08:57:06Z WARN host pipeline refused '+$Secret
) | Set-Content -LiteralPath (Join-Path $Private 'title-stderr-private.txt') -Encoding UTF8
@('Private content '+$Secret, 'title exit 0x887A0005', 'DROPPED indirect kind 2 (no host pipeline)') |
    Set-Content -LiteralPath (Join-Path $Private 'title-stdout-private.txt') -Encoding UTF8
& $Script -RunFolder $Run
$Zip=Join-Path $Run 'E089-offline-dred-counts.zip'
if (-not (Test-Path -LiteralPath $Zip -PathType Leaf)) { throw 'No E089 ZIP' }
$Extract=Join-Path $Root 'inspect'
Expand-Archive -LiteralPath $Zip -DestinationPath $Extract -Force
$Files=Get-ChildItem -LiteralPath $Extract -File
if ($Files.Count -ne 1 -or $Files[0].Name -cne 'E089-anonymous-dred-counts.txt') {
    throw 'Unexpected ZIP payload; only fixed schema permitted'
}
$Text=Get-Content -LiteralPath $Files[0].FullName -Raw
foreach ($Expected in @(
'format=E089-private-offline-dred-aggregate-v1',
'analysis_mode=offline_existing_logs_only',
'new_title_launch=false',
'scanned_lines=10',
'host_slow_submission_lines=1',
'host_max_slow_ms=11654',
'host_lists_at_max_slow=1',
'dred_no_breadcrumbs_lines=1',
'dred_stopped_command_marker_lines=1',
'dred_last_stopped_command_index=514',
'dred_last_stopped_command_total=1304',
'dred_last_stopped_op_code=5',
'gpu_pipeline_refused_lines=1',
'shader_translation_refused_lines=1',
'dxgi_device_removed_code_lines=1',
'dxgi_device_hung_code_lines=1'
)) {
    if (-not $Text.Contains($Expected)) { throw ('Missing expected safe metric: '+$Expected+[Environment]::NewLine+$Text) }
}
foreach ($PrivateText in @($Secret,$EvilHash,'0x148981EF0', 'title-stderr-private', $Root)) {
    if ($Text.Contains($PrivateText)) { throw 'Source-derived private content leaked into ZIP' }
}
foreach ($Line in ($Text -split '\r?\n')) {
    if ($Line.Trim() -and $Line -notmatch '^[a-z0-9_]+=[a-zA-Z0-9_-]*$') {
        throw ('Unsafe value in output: '+$Line)
    }
}
# Re-running offline should safely atomically replace ZIP and produce same counts.
& $Script -RunFolder $Run
$Second=Join-Path $Root 'inspect-second'
Expand-Archive -LiteralPath $Zip -DestinationPath $Second -Force
$Text2=Get-Content -LiteralPath (Join-Path $Second 'E089-anonymous-dred-counts.txt') -Raw
if ($Text2 -cne $Text) { throw 'E089 rerun not stable on unchanged private files' }
Write-Host 'E089 synthetic positive, privacy, repeatability: PASS'
# Invalid folder and absent files must refuse cleanly, without writing a ZIP.
$Wrong=Join-Path $Root 'not-an-e087-folder'
New-Item -ItemType Directory -Path $Wrong -Force | Out-Null
$Threw=$false
try { & $Script -RunFolder $Wrong | Out-Null } catch { $Threw=$true }
if (-not $Threw) { throw 'Invalid run folder not rejected' }
$Empty=Join-Path $Root 'E087-supervised-20261127-015635-ffffff'
New-Item -ItemType Directory -Path (Join-Path $Empty 'PRIVATE-logs-do-not-upload'),(Join-Path $Empty 'upload-only') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $Public 'E087-anonymous-status.txt') -Destination (Join-Path $Empty 'upload-only\E087-anonymous-status.txt')
$Threw=$false
try { & $Script -RunFolder $Empty | Out-Null } catch { $Threw=$true }
if (-not $Threw -or (Test-Path -LiteralPath (Join-Path $Empty 'E089-offline-dred-counts.zip'))) {
    throw 'No-log case did not fail closed'
}
Write-Host 'E089 invalid-folder and missing-logs: PASS'
Write-Host 'E089 Windows synthetic 4/4 contracts PASS; no game or GPU used'
