#Requires -Version 5.1
$ErrorActionPreference='Stop'
$P=(Resolve-Path 'scripts/research/owner-e100-d3d12-ids-offline.ps1').ProviderPath
$Tokens=$null;$Errors=$null
$null=[Management.Automation.Language.Parser]::ParseFile($P,[ref]$Tokens,[ref]$Errors)
if($Errors.Count){throw ('PowerShell syntax errors: '+($Errors|Out-String))}
$Content=Get-Content -LiteralPath $P -Raw
foreach($Bad in @('Start-Process','Invoke-WebRequest','git clone','curl ','VICTORY_SKIP_PIPELINES','VICTORY_SHADER_LOOP_LIMIT')){
  if($Content.Contains($Bad)){throw ('Forbidden capability: '+$Bad)}
}
$Base=Join-Path $env:TEMP ('e100-'+[guid]::NewGuid().ToString('N'))
$Run=Join-Path $Base 'E087-supervised-20261127-111111-aabbcc'
$Private=Join-Path $Run 'PRIVATE-logs-do-not-upload'
$Safe=Join-Path $Run 'upload-only'
New-Item -ItemType Directory -Force -Path $Private,$Safe|Out-Null
try {
  Set-Content -LiteralPath (Join-Path $Safe 'E087-anonymous-status.txt') -Value 'format=E087-durable-gpu-supervisor-v1'
  @(
    '2026 INFO host D3D12: message about PRIVATE_SHADER_fedcbaabcdef1234 id=940 severity=2'
    '2026 INFO host D3D12: message id=940 severity=2 title PRIVATE_PATH'
    '2026 INFO host D3D12: wave mismatch id=622 severity=2'
    '2026 INFO host D3D12: informational id=46 severity=3'
    '2026 INFO host D3D12: no id here'
    'host removed; commands 524..541 between its barriers: ; command 526 (op 6): dispatch 8x4x1 [compute SECRET_HASH] | title user data; command 527 (op 6): dispatch 1x1x1 [compute SECRET]'
    'host removed; command 528 (op 6): dispatch 128x64x1 [compute PRIVATE_CONTENT]'
  ) | Set-Content -LiteralPath (Join-Path $Private 'title-stderr-private.txt')
  & $P -RunFolder $Run
  $Z=Join-Path $Run 'E100-anonymous-d3d12-ids.zip'
  if(-not(Test-Path -LiteralPath $Z)){throw 'No ZIP'}
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $A=[IO.Compression.ZipFile]::OpenRead($Z)
  try {
    if($A.Entries.Count -ne 1){throw 'ZIP membership contract failed'}
    $Reader=[IO.StreamReader]::new($A.Entries[0].Open())
    try{$Out=$Reader.ReadToEnd()}finally{$Reader.Dispose()}
  } finally {$A.Dispose()}
  foreach($Must in @(
    'd3d12_debug_lines=5'
    'd3d12_id_parsed_lines=4'
    'd3d12_id_unparsed_lines=1'
    'd3d12_severity_2_warning=3'
    'd3d12_severity_3_info=1'
    'd3d12_severity_missing_or_other=1'
    'd3d12_id_622_wave_lane_count=1'
    'd3d12_id_940_descriptor_dimension=2'
    'dred_dispatch_op_lines=3'
    'dred_dispatch_geometry_parsed=3'
    'dispatch_group_1d=1'
    'dispatch_group_2d=2'
    'dispatch_total_groups_small_le64=2'
    'dispatch_total_groups_large_gt4096=1'
    'dispatch_largest_group_count=8192'
    'd3d12_top_01_id=940'
    'd3d12_top_01_count=2'
    'd3d12_top_02_id=46'
    'd3d12_top_02_count=1'
    'd3d12_top_03_id=622'
    'd3d12_top_03_count=1'
  )){if(-not $Out.Contains($Must)){throw ('Missing expected synthetic count: '+$Must)}}
  foreach($PrivateText in @('PRIVATE_SHADER','PRIVATE_PATH','SECRET_HASH','PRIVATE_CONTENT','title user data','fedcbaabcdef1234')){
    if($Out.Contains($PrivateText)){throw 'Private data leaked into E100 output'}
  }
  $First=$Out
  & $P -RunFolder $Run | Out-Null
  if((Get-Content -LiteralPath (Join-Path $Safe 'E100-anonymous-d3d12-ids.txt') -Raw) -cne $First){throw 'Non-deterministic rerun'}
  Remove-Item -LiteralPath (Join-Path $Private 'title-stderr-private.txt')
  $Caught=$false
  try{& $P -RunFolder $Run | Out-Null}catch{$Caught=$true}
  if(-not $Caught){throw 'Missing private logs incorrectly accepted'}
  Write-Host 'E100 SYNTHETIC PASS: fixed private-safe aggregate, deterministic repeat, missing-log refusal'
} finally { Remove-Item -LiteralPath $Base -Recurse -Force -ErrorAction SilentlyContinue }
