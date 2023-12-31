:: This can be used to get around the Execution Policy limitations

@echo on

::::::::::::::::::::::::::::
::  Place Arguments here  ::
::::::::::::::::::::::::::::


SET LocalRepository=$True
SET LocalRepositoryPath="http://hercules.cerberus.local:8624/nuget/Hercules/"
SET LocalRepositoryName="HERCULES"
SET DisableCommunityRepository=$False


::::::::::::::::::::::::::::
:: Run Powershell Script  ::
::::::::::::::::::::::::::::


Powershell -ExecutionPolicy Bypass -Command "& {$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $true) {Write-Host "This session is running with Administrator priviledges." -ForegroundColor DarkGreen} else {Write-Host "This session is not running with Administrator priviledges." -ForegroundColor DarkRed; $Host.UI.RawUI.WindowTitle = '[Not Admin]: ' + $host.UI.RawUI.WindowTitle; Write-Host "Please close this prompt and restart as admin" -ForegroundColor DarkRed; Write-Host "Press any key to exit..."; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); throw 'Session is not running with Administrator priviledges.';}; $scriptPath = 'https://raw.githubusercontent.com/gabriel-vanca/Chocolatey/main/Chocolatey_Deploy.ps1'; $WebClient = New-Object Net.WebClient;$deploymentScript = $WebClient.DownloadString($scriptPath); $deploymentScript = [Scriptblock]::Create($deploymentScript); Invoke-Command -ScriptBlock $deploymentScript -ArgumentList (%LocalRepository%, '%LocalRepositoryPath%', '%LocalRepositoryName%', %DisableCommunityRepository%) -NoNewScope; Write-Host 'Press any key to exit...';$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')}" -Verb RunAs -noexit
EXIT /B
