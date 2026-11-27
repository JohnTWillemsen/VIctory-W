#Requires -Version 5.1
# E087 pure synthetic Windows CI: no game, shaders, driver or proprietary data.
$ErrorActionPreference='Stop'
$Runner=(Resolve-Path 'scripts/research/owner-e087-durable-game-run.ps1').ProviderPath
$Tokens=$null; $Errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile($Runner,[ref]$Tokens,[ref]$Errors)
if($Errors.Count -ne 0){throw ('E087 PowerShell 5.1 syntax errors: '+($Errors | Out-String))}
$Root=Join-Path $env:RUNNER_TEMP 'E087-synthetic-only'
New-Item -ItemType Directory -Force -Path $Root | Out-Null
$PowerShell=Join-Path $PSHOME 'powershell.exe'
$Expected=(Get-FileHash -LiteralPath $PowerShell -Algorithm SHA256).Hash.ToLowerInvariant()
function Latest {
    return (Get-ChildItem -LiteralPath $Root -Directory -Filter 'E087-supervised-*' |
       Sort-Object CreationTime -Descending | Select-Object -First 1).FullName
}
function WaitFor([scriptblock]$Condition,[int]$Seconds=60) {
    for($i=0;$i -lt $Seconds*4;$i++){
        if(& $Condition){return}
        Start-Sleep -Milliseconds 250
    }
    throw ('Timeout after '+$Seconds+' seconds')
}
function Status([string]$Folder) {
    $File=Join-Path $Folder 'upload-only\E087-anonymous-status.txt'
    if(-not (Test-Path -LiteralPath $File)){return ''}
    return (Get-Content -LiteralPath $File -Raw)
}
function CheckZip([string]$Folder,[string]$Want) {
    $File=Join-Path $Folder 'E087-anonymous-summary.zip'
    if(-not (Test-Path -LiteralPath $File -PathType Leaf)){throw 'Missing anonymous ZIP'}
    $Stage=Join-Path $Folder 'validate-unzipped'
    Expand-Archive -LiteralPath $File -DestinationPath $Stage -Force
    $Text=Get-Content -LiteralPath (Join-Path $Stage 'E087-anonymous-status.txt') -Raw
    if(-not $Text.Contains($Want)){throw ('Missing expected ZIP state: '+$Want+'; got '+$Text)}
    foreach($Line in ($Text -split "\r?\n")){
        if($Line.Trim() -and $Line -notmatch '^[a-z0-9_]+=[^=]*$'){
            throw ('Malformed key=value line: '+$Line)
        }
    }
    if($Text.Contains($Root)){throw 'Local path leaked in anonymous ZIP'}
}
$Scenarios=@(
    @{Name='normal';Content="Write-Output 'scene audio'; exit 0";Code='0';Marker='outcome=EXIT_ZERO_NOT_VISUALLY_VERIFIED'},
    @{Name='crash';Content="Write-Output 'slow host submission'; Write-Output 'device removed 0x887A0006'; Write-Output 'shader does not translate'; exit 23";Code='23';Marker='outcome=EXIT_NONZERO_OR_CRASH'}
)
foreach($Scenario in $Scenarios) {
    $Fixture=Join-Path $Root ($Scenario.Name+'.ps1')
    Set-Content -LiteralPath $Fixture -Value $Scenario.Content -Encoding ASCII
    & $Runner -VictoryExe $PowerShell -ExpectedSha256 $Expected -ReportRoot $Root -Fixture -FixtureScript $Fixture
    $Folder=Latest
    if(-not (Test-Path -LiteralPath (Join-Path $Folder 'E087-anonymous-summary.zip'))){
        throw 'Initial durable checkpoint ZIP was not created before return'
    }
    WaitFor { (Status $Folder).Contains('status=TITLE_EXITED') }
    $Text=Status $Folder
    if(-not $Text.Contains($Scenario.Marker) -or -not $Text.Contains('title_exit_code='+$Scenario.Code)){
        throw ('Wrong result in '+$Scenario.Name+': '+$Text)
    }
    CheckZip $Folder $Scenario.Marker
    Write-Host ('E087 '+$Scenario.Name+' PASS')
    Start-Sleep -Milliseconds 1200
}
$Fixture=Join-Path $Root 'forced-kill.ps1'
Set-Content -LiteralPath $Fixture -Value "Write-Output 'audio continued'; Start-Sleep -Seconds 90; exit 0" -Encoding ASCII
& $Runner -VictoryExe $PowerShell -ExpectedSha256 $Expected -ReportRoot $Root -Fixture -FixtureScript $Fixture
$Folder=Latest
WaitFor { Test-Path -LiteralPath (Join-Path $Folder 'PRIVATE-logs-do-not-upload\game-pid.txt') }
$GameProcessId=[int](Get-Content -LiteralPath (Join-Path $Folder 'PRIVATE-logs-do-not-upload\game-pid.txt') -Raw)
Stop-Process -Id $GameProcessId -Force
WaitFor { (Status $Folder).Contains('status=TITLE_EXITED') }
if(-not (Status $Folder).Contains('outcome=EXIT_NONZERO_OR_CRASH')){throw 'Forced-kill exit not marked nonzero'}
CheckZip $Folder 'status=TITLE_EXITED'
Write-Host 'E087 forced title termination PASS'
Start-Sleep -Milliseconds 1200
$Fixture=Join-Path $Root 'monitor-kill.ps1'
Set-Content -LiteralPath $Fixture -Value 'Start-Sleep -Seconds 90; exit 0' -Encoding ASCII
& $Runner -VictoryExe $PowerShell -ExpectedSha256 $Expected -ReportRoot $Root -Fixture -FixtureScript $Fixture
$Folder=Latest
WaitFor { Test-Path -LiteralPath (Join-Path $Folder 'PRIVATE-logs-do-not-upload\game-pid.txt') }
$Private=Join-Path $Folder 'PRIVATE-logs-do-not-upload'
$GameProcessId=[int](Get-Content -LiteralPath (Join-Path $Private 'game-pid.txt') -Raw)
$WorkerProcessId=[int](Get-Content -LiteralPath (Join-Path $Private 'worker-pid.txt') -Raw)
Stop-Process -Id $WorkerProcessId -Force
Stop-Process -Id $GameProcessId -Force
WaitFor { -not (Get-Process -Id $WorkerProcessId -ErrorAction SilentlyContinue) }
& $Runner -Mode Recover -RunFolder $Folder
WaitFor { (Status $Folder).Contains('status=RECOVERED_AFTER_MONITOR_STOP') }
CheckZip $Folder 'status=RECOVERED_AFTER_MONITOR_STOP'
Write-Host 'E087 stopped-monitor recovery PASS'
Write-Host 'E087 4/4 synthetic scenarios PASS; no title or physical GPU used'
