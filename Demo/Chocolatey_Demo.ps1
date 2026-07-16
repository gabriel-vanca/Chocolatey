<#
.SYNOPSIS
    Demonstrates the popular Windows package manager Chocolatey.
.DESCRIPTION
	Installs a small number of basic tools so as to demonstrate
        the popular Windows package manager Chocolatey.

    Deployment tested on:
        - Windows 10
        - Windows 11
        - Windows Sandbox
        - Windows Server 2019
        - Windows Server 2022
        - Windows Server 2025

    Good practice is to download and configure these file as you require it.
    This is merely a demo.
.EXAMPLE
    PS> ./Chocolatey_Demo
.LINK
	https://github.com/gabriel-vanca/Chocolatey
.NOTES
	Author: Gabriel Vanca
#>

#Requires -RunAsAdministrator

# #Requires above is ignored for scriptblock/Invoke-Expression runs, so the privilege
# check must also be done manually.
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "This script requires administrator privileges. Run it from an elevated PowerShell session."
}

# TLS 1.3 exclusively on Windows 11 / Server 2022 and newer (build 20348+), TLS 1.2 on
# older Windows (12288 = Tls13, 3072 = Tls12; the Tls13 enum name needs .NET 4.8+).
# This script performs no downloads itself; kept for consistency with the deploy script.
if ([Environment]::OSVersion.Version.Build -ge 20348) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]12288
} else {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]3072
}

# Defaults for the "yes" repository answer; "custom" prompts for its own values.
$LocalRepositoryPath_ = "http://hercules.cerberus.local:8624/nuget/Hercules/"
$LocalRepositoryName_ = "Hercules.cerberus.local"


Write-Host "REMINDER: This is a demo of how to install and
            configure Chocolatey using Chocolatey_Deploy.ps1
            and then use Chocolatey to install software.
            You HAVE TO download and configure this file as you
            require it or fork the repo and edit as needed.
          -------------------------------------------------------
            AGAIN: This is merely a demo.
          -------------------------------------------------------" -ForegroundColor DarkRed

function Read-ValidatedChoice {
    param(
        [string]$Prompt,
        [string[]]$ValidAnswers
    )
    while ($true) {
        $answer = (Read-Host -Prompt $Prompt).Trim()
        if ($ValidAnswers -contains $answer) {
            return $answer
        }
        Write-Host "'$answer' is not a valid option. Valid options: $($ValidAnswers -join ', ')" -ForegroundColor DarkRed
    }
}

$availableMachines = @(
    'Server'
    'Workstation'
    'Laptop'
    'Gaming'
    'NAS'
)
Write-Host "Deployable machines:"
foreach ($machineName in $availableMachines) {
    Write-Host $machineName
}

$machineElected = Read-ValidatedChoice -Prompt "Type the name of the machine you are deploying" -ValidAnswers $availableMachines

# Checked up front so the user does not answer repository questions for a deployment
# that would be skipped anyway.
if (Test-Path "$Env:ProgramData/chocolatey/choco.exe") {
    Write-Host "Chocolatey is already installed. Skipping deployment and repository configuration." -ForegroundColor DarkYellow
} else {
    $LocalRepository_ = $False
    $DisableCommunityRepository_ = $False

    $localRepositoryOption = Read-ValidatedChoice -Prompt "Would you like to use $LocalRepositoryName_ as the main repository for Chocolatey (yes/no/custom)?" -ValidAnswers @('yes', 'no', 'custom')

    if ($localRepositoryOption -ne "no") {
        $LocalRepository_ = $True

        if ($localRepositoryOption -eq "custom") {
            Write-Host "Type the custom path of the repository you want to use."
            Write-Host "Example 1: http://10.10.10.1:8624/nuget/Thoth/"
            Write-Host "Example 2: http://hercules.cerberus.local:8624/nuget/Hercules/"
            $LocalRepositoryPath_ = Read-Host -Prompt "Type repository path"
            $LocalRepositoryName_ = Read-Host -Prompt "Type a name for the repository"
        }

        $disableCommunityAnswer = Read-ValidatedChoice -Prompt "Would you like to disable the Chocolatey Community Repository? (yes/no)" -ValidAnswers @('yes', 'no')
        $DisableCommunityRepository_ = ($disableCommunityAnswer -eq "yes")
    }

    Write-Host "Initialising Chocolatey deployment"

    # The deploy script sits in the repo root, one level above this Demo directory.
    # Parameters are passed by NAME: the two switches never bind positionally.
    # A deploy failure (no admin rights, failed install) must abort the demo, since the
    # installs below need a working Chocolatey; the catch only explains, then rethrows.
    try {
        & "$PSScriptRoot\..\Chocolatey_Deploy.ps1" `
            -LocalRepository:$LocalRepository_ `
            -LocalRepositoryPath $LocalRepositoryPath_ `
            -LocalRepositoryName $LocalRepositoryName_ `
            -DisableCommunityRepository:$DisableCommunityRepository_
    } catch {
        Write-Host "Chocolatey deployment failed: $($_.Exception.Message)" -ForegroundColor DarkRed
        Write-Host "Aborting the demo: the package installations below require a working Chocolatey." -ForegroundColor DarkRed
        throw
    }
}

$date = Get-Date
Write-Host "Deploying machine '$machineElected' on '$date' "

& "$PSScriptRoot\Core.ps1"

# $machineElected was validated against $availableMachines, which doubles as the
# dispatch table.
& "$PSScriptRoot\$machineElected.ps1"
