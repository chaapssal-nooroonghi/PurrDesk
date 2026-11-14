param([Parameter(Mandatory=$true)][string]$Layout,[Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
New-Item -ItemType Directory -Force $Output | Out-Null
$process=Start-Process (Join-Path $Layout 'PurrDesk.exe') -WorkingDirectory $Layout -PassThru
try {
 Start-Sleep -Seconds 8
 $process.Refresh()
 if ($process.HasExited) { throw "Desktop app exited before smoke check: $($process.ExitCode)" }
 $bounds=[Windows.Forms.SystemInformation]::VirtualScreen
 $bitmap=[Drawing.Bitmap]::new($bounds.Width,$bounds.Height)
 $graphics=[Drawing.Graphics]::FromImage($bitmap)
 try {
  $graphics.CopyFromScreen($bounds.Location,[Drawing.Point]::Empty,$bounds.Size)
  $bitmap.Save((Join-Path $Output 'windows-desktop-preview.png'),[Drawing.Imaging.ImageFormat]::Png)
 } finally { $graphics.Dispose();$bitmap.Dispose() }
 $settings=Join-Path $env:LOCALAPPDATA 'CatDesk\settings.json'
 if (!(Test-Path $settings)) { throw 'App did not create its user settings.' }
 $roster=Get-Content $settings -Raw -Encoding UTF8 | ConvertFrom-Json
 if ($roster.Cats.Count -ne 2) { throw 'Expected two bundled pets.' }
 foreach ($cat in $roster.Cats) {
  if ($cat.StretchImages.Count -ne 2) { throw 'Expected updated stretching photos.' }
  foreach ($photo in $cat.IdleImages+$cat.StretchImages) { if (!(Test-Path $photo)) { throw "Missing photo: $photo" } }
 }
 @{unpackaged_windows_launch=$true;settings_created=$true;bundled_pets=$roster.Cats.Count;packaged_install_tested=$false} | ConvertTo-Json | Set-Content (Join-Path $Output 'runtime-smoke.json') -Encoding UTF8
} finally { if (!$process.HasExited) { Stop-Process $process.Id -Force } }
