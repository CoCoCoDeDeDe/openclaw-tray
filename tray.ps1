$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DpiHelper {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr value);
  public static void Enable() {
    try { if (!SetProcessDpiAwarenessContext(new IntPtr(-4))) SetProcessDPIAware(); }
    catch { SetProcessDPIAware(); }
  }
}
"@
[DpiHelper]::Enable()
[System.Windows.Forms.Application]::EnableVisualStyles()

Add-Type -TypeDefinition @"
using System.Drawing;
using System.Windows.Forms;
public class DarkTable : ProfessionalColorTable {
  public override Color ToolStripDropDownBackground { get { return Color.FromArgb(26,26,32); } }
  public override Color ImageMarginGradientBegin { get { return Color.FromArgb(26,26,32); } }
  public override Color ImageMarginGradientMiddle { get { return Color.FromArgb(26,26,32); } }
  public override Color ImageMarginGradientEnd { get { return Color.FromArgb(26,26,32); } }
  public override Color MenuBorder { get { return Color.FromArgb(64,64,78); } }
  public override Color MenuItemBorder { get { return Color.FromArgb(255,128,72); } }
  public override Color MenuItemSelected { get { return Color.FromArgb(46,46,56); } }
  public override Color MenuItemSelectedGradientBegin { get { return Color.FromArgb(46,46,56); } }
  public override Color MenuItemSelectedGradientEnd { get { return Color.FromArgb(46,46,56); } }
  public override Color SeparatorDark { get { return Color.FromArgb(58,58,70); } }
  public override Color SeparatorLight { get { return Color.FromArgb(38,38,46); } }
}
"@

$here    = $PSScriptRoot
$cfgPath = Join-Path $here 'config.json'
$logFile = Join-Path $here 'tray-log.txt'
$pidFile = Join-Path $here 'tray.pid'
$icoPath = Join-Path $here 'assets\openclaw.ico'
$gwctl   = Join-Path $here 'gwctl.ps1'

$cfg = $null
if (Test-Path $cfgPath) { $cfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json }
$taskName = if ($cfg -and $cfg.taskName) { $cfg.taskName } else { 'OpenClaw Gateway' }
$port     = if ($cfg -and $cfg.port) { [int]$cfg.port } else { 18789 }
$cli      = if ($cfg -and $cfg.cliPath) { $cfg.cliPath } else { 'openclaw' }

$tmp = New-Object System.Drawing.Bitmap(1,1)
$S = [double]$tmp.HorizontalResolution / 96.0
$tmp.Dispose()
if ($S -lt 1) { $S = 1 }
function Px([double]$v) { return [int][Math]::Round($v * $S) }

function Log([string]$m) {
  ("$(Get-Date -Format 'HH:mm:ss')  $m") | Out-File $logFile -Append -Encoding utf8
}

function New-Dot([System.Drawing.Color]$c) {
  $d = Px 16
  $b = New-Object System.Drawing.Bitmap($d,$d)
  $g = [System.Drawing.Graphics]::FromImage($b)
  $g.SmoothingMode='AntiAlias'
  $g.Clear([System.Drawing.Color]::Transparent)
  $br = New-Object System.Drawing.SolidBrush($c)
  $m = [single](Px 3)
  $g.FillEllipse($br,$m,$m,[single]($d - 2*$m),[single]($d - 2*$m))
  $g.Dispose(); $br.Dispose()
  return $b
}

function Test-Port {
  $c = New-Object System.Net.Sockets.TcpClient
  try {
    $ar = $c.BeginConnect('127.0.0.1',$port,$null,$null)
    if ($ar.AsyncWaitHandle.WaitOne(300)) { $c.EndConnect($ar); return $true }
  } catch { } finally { $c.Close() }
  return $false
}

$ni = New-Object System.Windows.Forms.NotifyIcon
if (Test-Path $icoPath) { $ni.Icon = New-Object System.Drawing.Icon($icoPath,[System.Windows.Forms.SystemInformation]::SmallIconSize) } else { $ni.Icon = [System.Drawing.SystemIcons]::Application }
$ni.Text = 'OpenClaw Gateway'
$ni.Visible = $true
Set-Content -Path $pidFile -Value $PID -Encoding ASCII
Log ('tray started pid=' + $PID + ' scale=' + $S)

function Fire([string]$verb) {
  Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',('"' + $gwctl + '"'),$verb -WindowStyle Hidden
  Log ('fired ' + $verb)
}

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$menu.Renderer = New-Object System.Windows.Forms.ToolStripProfessionalRenderer(New-Object DarkTable)
$menu.Renderer.RoundedEdges = $false
$menu.BackColor = [System.Drawing.Color]::FromArgb(26,26,32)
$menu.ForeColor = [System.Drawing.Color]::FromArgb(235,235,240)
$menu.Font = New-Object System.Drawing.Font('Segoe UI',9.5,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Point)
$menu.Padding = New-Object System.Windows.Forms.Padding((Px 4))
$menu.ImageScalingSize = New-Object System.Drawing.Size((Px 16),(Px 16))
$menu.DropShadowEnabled = $true

$hdr = New-Object System.Windows.Forms.ToolStripLabel
$hdr.Text = '  OpenClaw'
$hdr.Font = New-Object System.Drawing.Font('Segoe UI',10.5,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point)
$hdr.ForeColor = [System.Drawing.Color]::FromArgb(255,140,80)
$hdr.AutoSize = $false
$hdr.Width = (Px 190)
$hdr.Height = (Px 26)
$menu.Items.Add($hdr) | Out-Null

$statLbl = New-Object System.Windows.Forms.ToolStripLabel
$statLbl.Text = '  detecting...'
$statLbl.Font = New-Object System.Drawing.Font('Segoe UI',8.5,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Point)
$statLbl.ForeColor = [System.Drawing.Color]::FromArgb(150,150,165)
$statLbl.AutoSize = $false
$statLbl.Width = (Px 190)
$statLbl.Height = (Px 22)
$menu.Items.Add($statLbl) | Out-Null
$menu.Items.Add('-') | Out-Null

function New-Item([string]$text,[System.Drawing.Color]$dot,[scriptblock]$onClick) {
  $it = New-Object System.Windows.Forms.ToolStripMenuItem($text)
  $it.Image = New-Dot $dot
  $it.Padding = New-Object System.Windows.Forms.Padding(0,(Px 4),0,(Px 4))
  $it.add_Click($onClick)
  return $it
}

$menu.Items.Add((New-Item 'Start Gateway' ([System.Drawing.Color]::FromArgb(80,220,140)) { Fire 'start'; $ni.ShowBalloonTip(1500,'OpenClaw','Start sent','Info') })) | Out-Null
$menu.Items.Add((New-Item 'Stop Gateway' ([System.Drawing.Color]::FromArgb(240,90,90)) { Fire 'stop'; $ni.ShowBalloonTip(1500,'OpenClaw','Stop sent','Info') })) | Out-Null
$menu.Items.Add((New-Item 'Restart' ([System.Drawing.Color]::FromArgb(250,190,80)) { Fire 'restart'; $ni.ShowBalloonTip(1500,'OpenClaw','Restart sent','Info') })) | Out-Null
$menu.Items.Add('-') | Out-Null

$iStatus = New-Item 'Status Details' ([System.Drawing.Color]::FromArgb(110,170,255)) {
  $ni.ShowBalloonTip(1000,'OpenClaw','Querying...','Info')
  $script:job = Start-Job -ScriptBlock { param($c) (& $c gateway status 2>&1 | Out-String).Trim() } -ArgumentList $cli
  $script:tmr2 = New-Object System.Windows.Forms.Timer
  $script:tmr2.Interval = 700
  $script:tmr2.add_Tick({
    if ($script:job.State -ne 'Running') {
      $script:tmr2.Stop()
      $t = Receive-Job $script:job -ErrorAction SilentlyContinue
      Remove-Job $script:job -Force -ErrorAction SilentlyContinue
      if (-not $t) { $t = '(no output)' }
      [System.Windows.Forms.MessageBox]::Show($t,'OpenClaw Gateway') | Out-Null
    }
  })
  $script:tmr2.Start()
}
$menu.Items.Add($iStatus) | Out-Null

$menu.Items.Add((New-Item 'Open Control UI' ([System.Drawing.Color]::FromArgb(160,160,180)) { Start-Process ('http://127.0.0.1:' + $port) })) | Out-Null
$menu.Items.Add('-') | Out-Null
$menu.Items.Add((New-Item 'Exit Tray' ([System.Drawing.Color]::FromArgb(120,120,135)) { $ni.Visible = $false; [System.Windows.Forms.Application]::Exit() })) | Out-Null

$ni.ContextMenuStrip = $menu
$ni.add_DoubleClick({ Start-Process ('http://127.0.0.1:' + $port) })

$poll = New-Object System.Windows.Forms.Timer
$poll.Interval = 4000
$poll.add_Tick({
  if (Test-Port) { $statLbl.Text = '  running'; $statLbl.ForeColor = [System.Drawing.Color]::FromArgb(80,220,140) }
  else { $statLbl.Text = '  stopped'; $statLbl.ForeColor = [System.Drawing.Color]::FromArgb(240,90,90) }
})
$poll.Start()

[System.Windows.Forms.Application]::Run()