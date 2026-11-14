param(
 [string]$IdentityName,
 [string]$Publisher,
 [string]$PublisherDisplayName,
 [switch]$Preview,
 [string]$Prebuilt,
 [string]$Output = (Join-Path $PSScriptRoot '..\releases\store-v106')
)
$ErrorActionPreference = 'Stop'
if ($Preview) {
 $IdentityName='PurrDesk.StorePreview'
 $Publisher='CN=PurrDesk-Store-Preview'
 $PublisherDisplayName='찹쌀누룽지'
} elseif (!$IdentityName -or !$Publisher -or !$PublisherDisplayName) {
 throw 'Partner Center identity name, publisher and publisher display name are required. Use -Preview only for packaging validation.'
}
if (!$Preview -and ($IdentityName -eq 'PurrDesk.StorePreview' -or $Publisher -eq 'CN=PurrDesk-Store-Preview')) { throw 'Preview identity is not accepted for Store submission.' }
$Output=[IO.Path]::GetFullPath($Output)
$stage=Join-Path $Output 'layout'
New-Item -ItemType Directory -Force $Output | Out-Null
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
if ($Prebuilt) {
 Copy-Item $Prebuilt $stage -Recurse -Force
} else {
 dotnet build (Join-Path $PSScriptRoot '..\PurrDesk.Framework\PurrDesk.Framework.csproj') -c Release -p:AssemblyName=PurrDesk -p:Version=1.0.6 -p:AssemblyVersion=1.0.6.0 -p:FileVersion=1.0.6.0 -o $stage
 if ($LASTEXITCODE -ne 0) { throw 'Store app build failed' }
 Get-ChildItem $stage -Recurse -Include *.pdb,*.lib,*.xml | Remove-Item -Force
 Copy-Item (Join-Path $PSScriptRoot '..\PurrDesk.Framework\THIRD-PARTY.md') (Join-Path $stage 'licenses\THIRD-PARTY.md')
}
$manifest=Get-Content (Join-Path $PSScriptRoot 'AppxManifest.template.xml') -Raw -Encoding UTF8
$manifest=$manifest.Replace('__IDENTITY_NAME__',[Security.SecurityElement]::Escape($IdentityName)).Replace('__PUBLISHER__',[Security.SecurityElement]::Escape($Publisher)).Replace('__PUBLISHER_DISPLAY_NAME__',[Security.SecurityElement]::Escape($PublisherDisplayName))
[IO.File]::WriteAllText((Join-Path $stage 'AppxManifest.xml'),$manifest,[Text.UTF8Encoding]::new($false))
# Render the same vector cat face used by the application's tray icon.
Add-Type -AssemblyName System.Drawing
$assets=Join-Path $stage 'Assets'; New-Item -ItemType Directory -Force $assets | Out-Null
function Draw-AppIcon([string]$Path,[int]$Size) {
 $bmp=[Drawing.Bitmap]::new($Size,$Size)
 $g=[Drawing.Graphics]::FromImage($bmp)
 $g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
 $g.Clear([Drawing.Color]::Transparent)
 $g.ScaleTransform($Size/40.0,$Size/40.0);$g.TranslateTransform(4,4)
 $fur=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(178,155,130))
 $eyes=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(65,54,45))
 try {
  $points=[Drawing.Point[]]@([Drawing.Point]::new(4,15),[Drawing.Point]::new(4,2),[Drawing.Point]::new(15,10),[Drawing.Point]::new(27,2),[Drawing.Point]::new(28,16))
  $g.FillPolygon($fur,$points);$g.FillEllipse($fur,3,7,26,24)
  $g.FillEllipse($eyes,9,16,3,4);$g.FillEllipse($eyes,21,16,3,4)
  $bmp.Save($Path,[Drawing.Imaging.ImageFormat]::Png)
 } finally { $eyes.Dispose();$fur.Dispose();$g.Dispose();$bmp.Dispose() }
}
Draw-AppIcon (Join-Path $assets 'StoreLogo.png') 50
foreach ($size in @(44,150)) {
 Draw-AppIcon (Join-Path $assets "Square${size}x${size}Logo.png") $size
 foreach ($scale in @(200,400)) { Draw-AppIcon (Join-Path $assets "Square${size}x${size}Logo.scale-${scale}.png") ($size*$scale/100) }
}
Draw-AppIcon (Join-Path $Output 'Store-listing-icon.png') 300
$tools=Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\makeappx.exe" | Sort-Object FullName -Descending
if (!$tools) { throw 'Windows SDK MakeAppx.exe is required.' }
$package=Join-Path $Output $(if($Preview){'Jipsa-Yeopjari-1.0.6.0-PREVIEW.msix'}else{'Jipsa-Yeopjari-1.0.6.0-Store.msix'})
& $tools[0].FullName pack /o /h SHA256 /d $stage /p $package
if ($LASTEXITCODE -ne 0) { throw 'MakeAppx schema or package validation failed' }
& $tools[0].FullName unpack /o /p $package /d (Join-Path $Output 'unpacked-validation')
if ($LASTEXITCODE -ne 0) { throw 'Package round-trip validation failed' }
$before=Get-ChildItem $stage -Recurse -File
foreach ($f in $before) {
 $relative=[IO.Path]::GetRelativePath($stage,$f.FullName)
 $unpacked=Join-Path (Join-Path $Output 'unpacked-validation') $relative
 if (!(Test-Path $unpacked) -or (Get-FileHash $f.FullName).Hash -ne (Get-FileHash $unpacked).Hash) { throw "Package round-trip changed $relative" }
}
@{preview=[bool]$Preview;identity=$IdentityName;publisher=$Publisher;version='1.0.6.0';sha256=(Get-FileHash $package).Hash.ToLower();bytes=(Get-Item $package).Length;makeappx=$tools[0].FullName;files=$before.Count;round_trip_verified=$true;store_submitted=$false} | ConvertTo-Json | Set-Content (Join-Path $Output 'package-verification.json') -Encoding UTF8
Write-Host "Validated package: $package"
