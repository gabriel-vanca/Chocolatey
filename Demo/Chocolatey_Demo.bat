:: This can be used to get around the Execution Policy and blocked files limitations.

@echo off

:: Unblock the whole repo (parent of this Demo directory), then relaunch
:: Chocolatey_Demo.ps1 elevated (Start-Process -Verb RunAs = UAC prompt).
:: -NoExit keeps the elevated window open; exit codes therefore do NOT propagate back
:: across the elevation boundary - for automation run the .ps1 directly from an
:: elevated shell. The script path is pre-quoted ([char]34) so paths with spaces
:: survive Start-Process's space-joined argument line.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath '%~dp0..' -Recurse | Unblock-File; try { Start-Process powershell.exe -Verb RunAs -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-File',('{1}{0}Chocolatey_Demo.ps1{1}' -f '%~dp0', [char]34)) } catch { Write-Host 'Elevation failed or was declined:' $_.Exception.Message; Read-Host 'Press Enter to exit' }"
EXIT /B
