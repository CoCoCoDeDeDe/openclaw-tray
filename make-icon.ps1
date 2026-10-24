$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root = $PSScriptRoot
$sizes = @(16,24,32,48,64,128,256)
function New-LobsterBitmap([int]$s) {
  $ss = 4
  $big = New-Object System.Drawing.Bitmap(($s*$ss),($s*$ss))
  $g = [System.Drawing.Graphics]::FromImage($big)
  $g.SmoothingMode='AntiAlias'; $g.TextRenderingHint='AntiAlias'
  $g.Clear([System.Drawing.Color]::Transparent)
  $rect = New-Object System.Drawing.Rectangle(0,0,($s*$ss-1),($s*$ss-1))
  $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect,[System.Drawing.Color]::FromArgb(255,255,150,70),[System.Drawing.Color]::FromArgb(255,205,45,55),55)
  $g.FillEllipse($br,0,0,($s*$ss-1),($s*$ss-1))
  $em = [char]::ConvertFromUtf32(0x1F99E)
  $font = New-Object System.Drawing.Font('Segoe UI Emoji',[single]($s*$ss*0.60),[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
  $sf = New-Object System.Drawing.StringFormat
  $sf.Alignment=[System.Drawing.StringAlignment]::Center
  $sf.LineAlignment=[System.Drawing.StringAlignment]::Center
  $g.DrawString($em,$font,[System.Drawing.Brushes]::White,(New-Object System.Drawing.RectangleF(0,0,($s*$ss),($s*$ss))),$sf)
  $g.Dispose()
  $small = New-Object System.Drawing.Bitmap($s,$s)
  $g2 = [System.Drawing.Graphics]::FromImage($small)
  $g2.InterpolationMode='HighQualityBicubic'; $g2.PixelOffsetMode='HighQuality'
  $g2.DrawImage($big,0,0,$s,$s)
  $g2.Dispose(); $big.Dispose()
  return $small
}
$pngData=@()
foreach ($s in $sizes) {
  $bmp = New-LobsterBitmap $s
  $ms = New-Object System.IO.MemoryStream
  $bmp.Save($ms,[System.Drawing.Imaging.ImageFormat]::Png)
  $pngData += ,@($s,$ms.ToArray())
  $ms.Dispose(); $bmp.Dispose()
}
$assets = Join-Path $root 'assets'
if (-not (Test-Path $assets)) { New-Item -ItemType Directory -Path $assets | Out-Null }
$fs2 = [System.IO.File]::Create((Join-Path $assets 'openclaw.ico'))
$bw = New-Object System.IO.BinaryWriter($fs2)
$bw.Write([UInt16]0); $bw.Write([UInt16]1); $bw.Write([UInt16]$pngData.Count)
$offset = 6 + 16*$pngData.Count
foreach ($e in $pngData) {
  $s=$e[0]; $data=$e[1]
  $w = if ($s -ge 256) { 0 } else { $s }
  $bw.Write([Byte]$w); $bw.Write([Byte]$w); $bw.Write([Byte]0); $bw.Write([Byte]0)
  $bw.Write([UInt16]1); $bw.Write([UInt16]32)
  $bw.Write([UInt32]$data.Length); $bw.Write([UInt32]$offset)
  $offset += $data.Length
}
foreach ($e in $pngData) { $bw.Write($e[1]) }
$bw.Flush(); $bw.Close(); $fs2.Close()
Write-Host 'icon generated: assets\openclaw.ico'