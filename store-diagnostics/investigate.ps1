$ErrorActionPreference='Stop'
$out=Join-Path $env:GITHUB_WORKSPACE 'diagnostics';New-Item -ItemType Directory -Force $out | Out-Null
Start-Transcript (Join-Path $out 'transcript.txt')
$cert=$null;$trusted=$null;$package=$null
try {
 Get-ComputerInfo -Property WindowsProductName,WindowsVersion,OsBuildNumber | Format-List
 [Environment]::Is64BitProcess
 gh api repos/chaapssal-nooroonghi/PurrDesk/actions/artifacts/14111501753/zip > source-artifact.zip
 if($LASTEXITCODE -ne 0){throw 'Could not retrieve the original validation artifact'}
 Expand-Archive source-artifact.zip original
 $msix=(Get-ChildItem original -Recurse -Filter Jipsa-Yeopjari-1.0.7.0-Store.msix | Select-Object -First 1).FullName
 if((Get-FileHash $msix).Hash.ToLower() -ne 'a1db12d550a8b848d2bf559cc2730d834d280f888a3d8167b696474e7e16ea45'){throw 'Original package SHA mismatch'}
 $layout=Join-Path $env:RUNNER_TEMP 'original-unpacked';[IO.Compression.ZipFile]::ExtractToDirectory($msix,$layout)
 Add-Type -TypeDefinition (Get-Content probe.cs -Raw)
 $exe=Join-Path $layout 'PurrDesk.exe'
 [ManifestProbe]::Probe($exe) | Tee-Object (Join-Path $out 'unpacked-native-probe.txt')
 $kits="${env:ProgramFiles(x86)}\Windows Kits\10"
 $mt=(Get-ChildItem "$kits/bin/*/x64/mt.exe" | Sort-Object FullName -Descending | Select-Object -First 1).FullName
 & $mt "-inputresource:$exe;#1" "-out:$out/extracted.manifest"
 & $mt -manifest "$out/extracted.manifest" -validate_manifest
 "mt exit=$LASTEXITCODE" | Set-Content "$out/mt-validation.txt"
 $wack=Join-Path $kits 'App Certification Kit/appcert.exe'
 if(!(Test-Path $wack)) {
  $sdk=Join-Path $env:RUNNER_TEMP 'winsdksetup.exe'
  Invoke-WebRequest 'https://download.microsoft.com/download/e6cfffdc-0d3e-4c6c-96d7-d491da459a07/KIT_BUNDLE_WINDOWSSDK_MEDIACREATION/winsdksetup.exe' -OutFile $sdk
  $sig=Get-AuthenticodeSignature $sdk;if($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'Microsoft Corporation'){throw 'SDK signature check failed'}
  $installer=Start-Process $sdk -ArgumentList '/quiet','/norestart','/features','OptionId.WindowsSoftwareLogoToolkit' -PassThru
  if(!$installer.WaitForExit(600000)){$installer.Kill();throw 'SDK install timeout'}
  "SDK installer exit=$($installer.ExitCode)"
 }
 if(!(Test-Path $wack)){throw 'WACK unavailable after SDK install'}
 (Get-Item $wack).VersionInfo | Format-List | Out-File "$out/wack-version.txt"
 & $wack /? 2>&1 | Out-File "$out/wack-help.txt"
 Get-ChildItem (Split-Path $wack) -File | Select-Object Name,Length,@{N='Version';E={$_.VersionInfo.FileVersion}} | ConvertTo-Json | Set-Content "$out/wack-files.json"
 # Sign only a temporary CI copy. Never upload certificate, key or signed package.
 $signed=Join-Path $env:RUNNER_TEMP 'ci-test-only.msix';Copy-Item $msix $signed
 $subject='CN=DE7DDEC8-9C61-4EC5-BFE6-81123A68DFC1'
 $cert=New-SelfSignedCertificate -Type CodeSigningCert -Subject $subject -CertStoreLocation Cert:\CurrentUser\My -NotAfter (Get-Date).AddDays(1)
 $cer=Join-Path $env:RUNNER_TEMP 'ci-test-only.cer';Export-Certificate -Cert $cert -FilePath $cer | Out-Null
 $trusted=Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\TrustedPeople
 $sign=(Get-ChildItem "$kits/bin/*/x64/signtool.exe" | Sort-Object FullName -Descending | Select-Object -First 1).FullName
 & $sign sign /fd SHA256 /sha1 $cert.Thumbprint $signed
 if($LASTEXITCODE -ne 0){throw 'CI signing failed'}
 Add-AppxPackage -Path $signed
 $package=Get-AppxPackage -Name Chaapssal-Nooroongghi.10202156D8DE9
 if(!$package){throw 'CI package installation not found'}
 $package | Select-Object Name,Version,PackageFullName,InstallLocation | ConvertTo-Json | Set-Content "$out/installed-package.json"
 [ManifestProbe]::Probe((Join-Path $package.InstallLocation 'PurrDesk.exe')) | Tee-Object "$out/installed-native-probe.txt"
 & $wack reset | Out-File "$out/wack-reset.txt"
 & sxstrace.exe Trace "-logfile:$out/sxs.etl" -nostop
 $test=Start-Process $wack -ArgumentList 'test','-packagefullname',$package.PackageFullName,'-reportoutputpath',"$out/wack-report.xml" -PassThru -RedirectStandardOutput "$out/wack-stdout.txt" -RedirectStandardError "$out/wack-stderr.txt"
 if(!$test.WaitForExit(600000)){$test.Kill();throw 'WACK timeout'}
 "WACK exit=$($test.ExitCode)" | Set-Content "$out/wack-exit.txt"
 & sxstrace.exe StopTrace
 & sxstrace.exe Parse "-logfile:$out/sxs.etl" "-outfile:$out/sxs.txt"
} catch {
 $_ | Format-List * -Force | Out-File "$out/error.txt"
 Write-Host "Diagnostic limitation: $($_.Exception.Message)"
} finally {
 if($package){Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Continue}
 if($trusted){Remove-Item ("Cert:\LocalMachine\TrustedPeople\"+$trusted.Thumbprint) -ErrorAction Continue}
 if($cert){Remove-Item ("Cert:\CurrentUser\My\"+$cert.Thumbprint) -DeleteKey -ErrorAction Continue}
 if(Test-Path $msix){Get-FileHash $msix | Format-List | Out-File "$out/original-hash-after.txt"}
 'No Store submission; original MSIX never modified; temporary CI installation and cert cleanup attempted.' | Set-Content "$out/scope.txt"
 Get-ChildItem $out -File | Where-Object { $_.Extension -in @(".txt", ".xml") -and $_.Name -ne "transcript.txt" } | ForEach-Object { Write-Output ("DIAGNOSTIC FILE: "+$_.Name);Get-Content $_.FullName }
 Stop-Transcript
}
