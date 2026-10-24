param(
  [string]$TaskName = 'OpenClaw Gateway',
  [int]$Port = 18789,
  [switch]$NoStartup
)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot

Write-Host '== OpenClaw Tray installer ==' -ForegroundColor Cyan

# 1. locate openclaw CLI
$cliPath = $null
$cmd = Get-Command openclaw -ErrorAction SilentlyContinue
if ($cmd) { $cliPath = $cmd.Source }
else {
  $fallback = Join-Path $env:APPDATA 'npm\openclaw.cmd'
  if (Test-Path $fallback) { $cliPath = $fallback }
}
if (-not $cliPath) {
  Write-Host 'ERROR: openclaw CLI not found in PATH.' -ForegroundColor Red
  Write-Host 'Install OpenClaw first, or edit config.json manually.' -ForegroundColor Yellow
  exit 1
}
Write-Host ('CLI: ' + $cliPath)

# 2. icon
$ico = Join-Path $here 'assets\openclaw.ico'
if (-not (Test-Path $ico)) {
  Write-Host 'Icon missing, generating...'
  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'make-icon.ps1')
}

# 3. config
$cfg = [ordered]@{ taskName = $TaskName; port = $Port; cliPath = $cliPath }
$cfg | ConvertTo-Json | Out-File (Join-Path $here 'config.json') -Encoding utf8
Write-Host ('Config written: task=' + $TaskName + ' port=' + $Port)

# 4. shortcuts
$ws = New-Object -ComObject WScript.Shell
$wscript = Join-Path $env:SystemRoot 'System32\wscript.exe'
$vbs = Join-Path $here 'run-tray.vbs'
$targets = @(
  [Environment]::GetFolderPath('Desktop'),
  (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs')
)
if (-not $NoStartup) { $targets += [Environment]::GetFolderPath('Startup') }

foreach ($t in $targets) {
  $lnkPath = Join-Path $t 'OpenClaw Tray.lnk'
  $lnk = $ws.CreateShortcut($lnkPath)
  $lnk.TargetPath = $wscript
  $lnk.Arguments = '"' + $vbs + '"'
  $lnk.IconLocation = $ico + ',0'
  $lnk.Description = 'OpenClaw Gateway'
  $lnk.WindowStyle = 7
  $lnk.Save()
  Write-Host ('Shortcut: ' + $lnkPath)
}

Write-Host ''
Write-Host 'Done. Launch OpenClaw Tray from the desktop shortcut.' -ForegroundColor Green
Write-Host 'Note: the Gateway itself must be installed as a scheduled task:' -ForegroundColor DarkGray
Write-Host '      openclaw gateway install' -ForegroundColor DarkGray