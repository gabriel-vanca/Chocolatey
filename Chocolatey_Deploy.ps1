<#
.SYNOPSIS
    Install and configures the popular Windows package manager Chocolatey.
.DESCRIPTION
	1. Checks whether chocolatey is already installed.
        - Terminates the script if it is so as to avoid misconfiguring.
    2. If it isn't installed yet, it install chocolatey.
    3. Verifies if installation has been succesfull
    4. Configures the default repository as per set parameters (see below)
    5. Sets an auto-update configuration
    6. Installs a package cache cleaning utility
    7. Installs the Chocolatey GUI tool

    Deployment tested on:
        - Windows 10
        - Windows 11
        - Windows Sandbox
        - Windows Server 2019
        - Windows Server 2022
        - Windows Server 2022 vNext (Windows Server 2025)
.PARAMETER LocalRepository
    (Optional)
    Enables a local repository.
    Leave blank to use the Chocolatey Community Repository.
    Note that using the Community Repository can run you into traffic
        limits in a multi-machine deployment scenario.
.PARAMETER LocalRepositoryPath
    (Optional)
	Specifies the full FQDN or IP, port and path of the local repository.
.PARAMETER LocalRepositoryName
    (Optional)
	Specifies the name of the local repository.
.PARAMETER DisableCommunityRepository
    (Optional)
	Allows disabling the Community Repository entirely.
    This will only work if a valid local repository has been added.
    Usually there should be no need to use this unless you're specifically concerned
        about the security of packages from outside your organisation.
.EXAMPLE
    To use the default Chocolatey Community Repository, run this:
	    PS> ./Chocolatey_Deploy
    To use a local repository, run either of these:
        PS> ./Chocolatey_Deploy $True "http://10.10.10.1:8624/nuget/Thoth/" "THOTH" $False
        PS> ./Chocolatey_Deploy $True "http://hercules.cerberus.local:8624/nuget/Hercules/" "HERCULES" $False
    The exact port and form of the path for the local repository will depend on
        the repository software you are using.
    In the examples above, the repository software used is the Inedo ProGet free software.
        https://inedo.com/proget
        Inedo ProGet can be deployed on Windows (including Windows Server with a free ProGet license),
            as well as Linux Docker containers.
            The packages can be stored locally or on an SMB/NFS network share.
                Please make sure sufficient storage is available.
            ProGet can install its own SQL Express database, or be configured with
            an external SQL database such as the free edition of Windows SQL Server.
        The paid Inedo ProGet versions also support retention policies, LDAP/AD Integration, Load Balancing,
            High Availability & Automatic Failover, Multi-Site Replication and AWS/Azure Packet Cloud Storage.
.LINK
	https://github.com/gabrielvanca/Chocolatey
.NOTES
	Author: Gabriel Vanca
#>


param(
        [Switch]$LocalRepository = $false,
        [string]$LocalRepositoryPath = "",
        [string]$LocalRepositoryName = "",
        [Switch]$DisableCommunityRepository = $false
     )


#Requires -RunAsAdministrator

# Force use of TLS 1.2 for all downloads.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Running with the following paramters:"
Write-Host "LocalRepository: $LocalRepository"
if ($LocalRepository -eq $True) {
    Write-Host "LocalRepositoryPath: $LocalRepositoryPath"
    Write-Host "LocalRepositoryName: $LocalRepositoryName"
    Write-Host "DisableCommunityRepository: $DisableCommunityRepository"
}
Write-Host "Starting proceedings"

# Expected path of the choco.exe file.
$chocoInstallPath = "$Env:ProgramData/chocolatey/choco.exe"
if (Test-Path "$chocoInstallPath") {
    Write-Host ""
    Write-Error "Chocolatey is already installed."
    Write-Host ""
    Write-Host ""
    Start-Sleep -Seconds 7
    throw "Chocolatey is already installed."
} else {
    Write-Host "No existing Chocolatey installation found. Beginning installation."

    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    if ($LastExitCode -eq 3010) {
        Write-Host 'The recent changes indicate a reboot is necessary. Please reboot at your earliest convenience.'  -ForegroundColor Magenta
    }

    Write-Host "Refreshing terminal"
    # Make `refreshenv` available right away, by defining the $env:ChocolateyInstall
    # variable and importing the Chocolatey profile module.
    $env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."   
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    Update-SessionEnvironment
    refreshenv

    Write-Host "Testing that choco was installed..."
    choco
    if (Test-Path "$chocoInstallPath") {
        Write-Host "Chocolatey installation succesful" -ForegroundColor DarkGreen
    } else {
        Write-Host "Chocolatey installation failure" -ForegroundColor DarkRed
        Start-Sleep -Seconds 5
        throw "Chocolatey installation failure"
    }
}

Write-Host "Configuring Chocolatey Sources"

# Auto confirm package installations (no need to pass -y)
choco feature enable -n allowGlobalConfirmation -y

# Configure Sources. Higher values means higher priority.
if($LocalRepository) {
    Write-Host "Trying to use a local repository"
    if([string]::IsNullOrEmpty($LocalRepositoryPath)) {
        Write-Error "The local repository path is null or empty."
        $LocalRepository = $False
    } else {
        if([string]::IsNullOrEmpty($LocalRepositoryName)) {
            Write-Error "The local repository name is null or empty."
            $LocalRepository = $False
        } else {
            try{
                choco source add -n $LocalRepositoryName -s $LocalRepositoryPath --priority=10
                Write-Host "Using Chocolatey local repository $LocalRepositoryName as main source."

                if($DisableCommunityRepository) {
                    choco source disable -n=chocolatey
                    Write-Host "Disabled Chocolatey Community Repository"
                }

            } catch {
                Write-Host "*****************************************************************" -ForegroundColor DarkRed
                Write-Host "Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])" -ForegroundColor DarkRed
                Write-Host "Failed to add local repository and/or disable community repository." -ForegroundColor DarkRed
                Write-Host "*****************************************************************" -ForegroundColor DarkRed
                $LocalRepository = $False
            }
        }
    }
}

if($LocalRepository -eq $False) {
    Write-Host "Using Chocolatey Community Repository as main source."
    Write-Host "Note that if you have multiple machines/VMs running on your local network, `n     you will run into the Chocolatey Community Repository traffic limit." -ForegroundColor DarkYellow
}

Write-Host "Printing Chocolatey sources list:"
choco source list
Write-Host "[END LIST]"

Write-Host "Configuring Chocolatey Updates and Cleaning"

<#
 Creates a Windows Scheduled Task to run "choco upgrade all -y" with enhanced options at a time and frequency you specify
 And because sometimes package installations go wrong, it will also create a Windows Scheduled Task to
 run "taskkill /im choco.exe /f /t" to stop the Chocolatey (choco.exe) process and all child processes at a time you specify.
 Runs "choco upgrade all -y" daily at 3 AM and aborts it at 6 AM.
#>
choco install choco-upgrade-all-at -y --params "'/DAILY:yes /TIME:03:00 /ABORTTIME:06:00'"

# Set it and forget it! Choco-Cleaner cleans up your Chocolatey installation
# every Sunday at 11 PM in the background so you don't have to be bothered with it.
choco install choco-cleaner -y

Write-Host "Installing and Configuring Chocolatey GUI"

# Chocolatey GUI
choco install chocolateygui -y --params "'/Global /ShowConsoleOutput=$true /PreventAutomatedOutdatedPackagesCheck=$true /DefaultToTileViewForLocalSource=$false /DefaultToTileViewForRemoteSource=$false /DefaultToDarkMode=$true'"

Write-Host "Chocolatey Configuration Completed"
