:: Standalone bootstrapper that also gets around Execution Policy limitations: runs
:: the local Chocolatey_Deploy.ps1 if present next to this file, otherwise downloads
:: it from GitHub (single-file deployment of a bare machine).

@echo off

::::::::::::::::::::::::::::
::  Place Arguments here  ::
::::::::::::::::::::::::::::

:: Set LocalRepository to $True (with path/name adjusted) to use your own repository.
:: Set AutoUpdate to $True to configure automatic daily package updates.
:: Set ChocoGUI to $True to install the Chocolatey GUI tool.
:: Values must not contain quote characters.
SET LocalRepository=$False
SET LocalRepositoryPath=http://hercules.cerberus.local:8624/nuget/Hercules/
SET LocalRepositoryName=HERCULES
SET DisableCommunityRepository=$False
SET AutoUpdate=$False
SET ChocoGUI=$False


::::::::::::::::::::::::::::
:: Run Powershell Script  ::
::::::::::::::::::::::::::::

:: The elevated child (Start-Process -Verb RunAs = UAC prompt) prefers the local
:: sibling script; otherwise it downloads from GitHub (TLS 1.3 on build 20348+, else
:: TLS 1.2; 12288 = Tls13, 3072 = Tls12) and dot-sources it as a scriptblock. Both
:: branches pass every parameter BY NAME, so no positional order matters anywhere.
:: -NoExit keeps the window open; exit codes therefore do NOT propagate back across
:: the elevation boundary - for automation run Chocolatey_Deploy.ps1 directly from
:: an elevated shell.
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process powershell.exe -Verb RunAs -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-Command','$localScript = ''%~dp0Chocolatey_Deploy.ps1''; if (Test-Path -LiteralPath $localScript) { Write-Host ''Running local deployment script:'' $localScript; & $localScript -LocalRepository:%LocalRepository% -LocalRepositoryPath ''%LocalRepositoryPath%'' -LocalRepositoryName ''%LocalRepositoryName%'' -DisableCommunityRepository:%DisableCommunityRepository% -AutoUpdate:%AutoUpdate% -ChocoGUI:%ChocoGUI% } else { Write-Host ''No local deployment script found. Downloading from GitHub.''; if ([Environment]::OSVersion.Version.Build -ge 20348) { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]12288 } else { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]3072 }; $scriptPath = ''https://raw.githubusercontent.com/gabriel-vanca/Chocolatey/main/Chocolatey_Deploy.ps1''; $WebClient = New-Object Net.WebClient; $deploymentScript = $WebClient.DownloadString($scriptPath); $deploymentScript = [Scriptblock]::Create($deploymentScript); . $deploymentScript -LocalRepository:%LocalRepository% -LocalRepositoryPath ''%LocalRepositoryPath%'' -LocalRepositoryName ''%LocalRepositoryName%'' -DisableCommunityRepository:%DisableCommunityRepository% -AutoUpdate:%AutoUpdate% -ChocoGUI:%ChocoGUI% }') } catch { Write-Host 'Elevation failed or was declined:' $_.Exception.Message; Read-Host 'Press Enter to exit' }"
EXIT /B
