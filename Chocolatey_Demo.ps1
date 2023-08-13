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
        - Windows Server 2022 vNext (Windows Server 2025)
    
    Good practice is to download and configure these file as you require it.
    This is merely a demo.
.EXAMPLE
    PS> ./Chocolatey_Demo
.LINK
	https://github.com/gabrielvanca/Chocolatey
.NOTES
	Author: Gabriel Vanca
#>

#Requires -RunAsAdministrator

# Force use of TLS 1.2 for all downloads.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

[Switch]$LocalRepository_ = $False
[string]$LocalRepositoryPath_ = "http://hercules.cerberus.local:8624/nuget/Hercules/"
[string]$LocalRepositoryName_ = "Hercules.cerberus.local"
[Switch]$DisableCommunityRepository_ = $False


Write-Host "REMINDER: This is a demo of how to install and
            configure Chocolatey using Chocolatey_Deploy.ps1
            and then use Chocolatey to install software.
            You HAVE TO download and configure this file as you
            require it or fork the repo and edit as needed.
          -------------------------------------------------------
            AGAIN: This is merely a demo.
          -------------------------------------------------------" -ForegroundColor DarkRed

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

Write-Host "Type the name of the machine you are deploying."
$machineElected = Read-Host
while($availableMachines -notcontains $machineElected) {
    Write-Host ("Machine name is not valid. Please type a valid name.") -ForegroundColor DarkRed
    $machineElected = Read-Host
}

$localRepositoryOption = Read-Host -Prompt "Would you like to use $LocalRepositoryName_ as the main repository for Chocolatey (yes/no/custom)?"
while($localRepositoryOption -ne "yes" -and $localRepositoryOption -ne "no" -and $localRepositoryOption -ne "custom") {
    Write-Host ("Option is not valid. Please choose a valid option.") -ForegroundColor DarkRed
    $localRepositoryOption = Read-Host -Prompt "Would you like to use $LocalRepositoryName_ as the main repository for Chocolatey (yes/no/custom)?"
}

if($LocalRepositoryOption -eq "n") {
    $LocalRepository_ = $False
    $DisableCommunityRepository_ = $False
} else {
    $LocalRepository_ = $True

    if($localRepositoryOption -eq "custom") {
        Write-Host "Type the custom path of the repository you want to use."
        Write-Host "Example 1: http://10.10.10.1:8624/nuget/Thoth/"
        Write-Host "Example 2: http://hercules.cerberus.local:8624/nuget/Hercules/"
        $LocalRepositoryPath_ = Read-Host -Prompt "Type repository path"
        $LocalRepositoryName_ = Read-Host -Prompt "Type a name for the repository"
    }

    $DisableCommunityRepository_Option = Read-Host -Prompt "Would you like to disable the Chocolatey Community Repository? (yes/no)"
    while($DisableCommunityRepository_Option -ne "yes" -and $DisableCommunityRepository_Option -ne "no") {
        Write-Host ("Option is not valid. Please choose a valid option.") -ForegroundColor DarkRed
        $DisableCommunityRepository_Option = Read-Host -Prompt "Would you like to disable the Chocolatey Community Repository? (yes/no)"
    }

    if($DisableCommunityRepository_Option -eq "yes") {
        $DisableCommunityRepository_ = $True
    } else {
        $DisableCommunityRepository_ = $False
    }
}


Write-Host "Initialising Chocolatey deployment"

$scriptPath = "https://raw.githubusercontent.com/gabriel-vanca/Chocolatey/main/Chocolatey_Deploy.ps1"
$WebClient = New-Object Net.WebClient
$deploymentScript = $WebClient.DownloadString($scriptPath)
$deploymentScript = [Scriptblock]::Create($deploymentScript)
Invoke-Command -ScriptBlock $deploymentScript -ArgumentList ($LocalRepository_, $LocalRepositoryPath_, $LocalRepositoryName_, $DisableCommunityRepository__) -NoNewScope

$date = Get-Date
Write-Host "Deploying machine '$machineElected' on '$date' "

& "$PSScriptRoot\Demo\Core.ps1"

switch ($machineElected) {
    'Server'
    {   
        & "$PSScriptRoot\Demo\Server.ps1"
    }
    'Workstation'
    {
        & "$PSScriptRoot\Demo\Workstation.ps1"
    }
    'Laptop'
    {
        & "$PSScriptRoot\Demo\Laptop.ps1"
    }
    'Gaming'
    {
        & "$PSScriptRoot\Demo\Gaming.ps1"
    }
    'NAS'
    {
        & "$PSScriptRoot\Demo\NAS.ps1"
    }
}
