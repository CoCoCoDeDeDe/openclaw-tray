$ErrorActionPreference = 'SilentlyContinue'
$here = $PSScriptRoot
Write-Host 'Removing shortcuts...'
$names = @(
  [Environment]::GetFolderPath('Desktop'),
  (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'),
  [Environment]::GetFolderPath('Startup')
)
foreach ($t in $names) {
  $p = Join-Path $t 'OpenClaw Tray.lnk'
  if (Test-Path $p) { Remove-Item $p -Force; Write-Host ('removed ' + $p) }
}
$pidFile = Join-Path $here 'tray.pid'
if (Test-Path $pidFile) {
  $trayPid = (Get-Content $pidFile -Raw).Trim()
  if ($trayPid) { & taskkill.exe /PID $trayPid /F | Out-Null; Write-Host ('stopped tray pid=' + $trayPid) }
  Remove-Item $pidFile -Force
}
Write-Host 'Uninstalled. The OpenClaw Gateway service was NOT touched.' -ForegroundColor Green