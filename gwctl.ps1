param([Parameter(Mandatory=$true)][ValidateSet('start','stop','restart','status')][string]$Action)
$ErrorActionPreference = 'SilentlyContinue'
$here = $PSScriptRoot
$log  = Join-Path $here 'tray-log.txt'
$cfg  = $null
$cfgPath = Join-Path $here 'config.json'
if (Test-Path $cfgPath) { $cfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json }
$task = if ($cfg -and $cfg.taskName) { $cfg.taskName } else { 'OpenClaw Gateway' }
$cli  = if ($cfg -and $cfg.cliPath) { $cfg.cliPath } else { 'openclaw' }
function Log([string]$m) { ("$(Get-Date -Format 'HH:mm:ss')  $m") | Out-File $log -Append -Encoding utf8 }
Log ('action=' + $Action)
switch ($Action) {
  'start'   { & schtasks.exe /run /tn $task *>> $log }
  'stop'    { & $cli gateway stop *>> $log; if ($LASTEXITCODE -ne 0) { Log 'cli failed, fallback schtasks /end'; & schtasks.exe /end /tn $task *>> $log } }
  'restart' { & $cli gateway stop *>> $log; if ($LASTEXITCODE -ne 0) { & schtasks.exe /end /tn $task *>> $log }; Start-Sleep -Seconds 3; & schtasks.exe /run /tn $task *>> $log }
  'status'  { & $cli gateway status *>> $log }
}
Log ('done ' + $Action + ' exit=' + $LASTEXITCODE)