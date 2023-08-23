@REM This can be used to get around the Execution Policy and blocked files limitations

@echo on

::::::::::::::::::::::::::::
:: Run Powershell Script  ::
::::::::::::::::::::::::::::

SET PowershellCmd=Start-Process powershell.exe -Argument '-noprofile -executionpolicy bypass -file "%~dp0Chocolatey_Demo.ps1"
powershell -Command "& {Get-ChildItem -Path '%~dp0' -Recurse | Unblock-File; %PowershellCmd%'}" -Verb RunAs
