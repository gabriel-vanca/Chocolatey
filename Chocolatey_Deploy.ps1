<#
.SYNOPSIS
    Install and configures the popular Windows package manager Chocolatey.
.DESCRIPTION
	1. Checks whether chocolatey is already installed.
        - Skips deployment if it is, leaving the existing installation untouched.
    2. If it isn't installed yet, it installs chocolatey.
    3. Verifies if installation has been successful
    4. Configures the default repository as per set parameters (see below)
    5. Installs a package cache cleaning utility
    6. Sets an auto-update configuration (only with -AutoUpdate)
    7. Installs the Chocolatey GUI tool (only with -ChocoGUI)

    Deployment tested on:
        - Windows 10
        - Windows 11
        - Windows Sandbox
        - Windows Server 2019
        - Windows Server 2022
        - Windows Server 2025
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
.PARAMETER AutoUpdate
    (Optional)
    Sets up automatic daily package updates via the choco-upgrade-all-at package
        (a scheduled task runs "choco upgrade all -y" at 3 AM, aborted at 6 AM).
    Off by default.
.PARAMETER ChocoGUI
    (Optional)
    Installs the Chocolatey GUI tool.
    Off by default.
.EXAMPLE
    To use the default Chocolatey Community Repository, run this:
	    PS> ./Chocolatey_Deploy -AutoUpdate:$False -ChocoGUI:$False
    To use a local repository, run either of these:
        PS> ./Chocolatey_Deploy -LocalRepository -LocalRepositoryPath "http://10.10.10.1:8624/nuget/Thoth/" -LocalRepositoryName "THOTH" -AutoUpdate:$False -ChocoGUI:$False
        PS> ./Chocolatey_Deploy -LocalRepository -LocalRepositoryPath "http://hercules.cerberus.local:8624/nuget/Hercules/" -LocalRepositoryName "HERCULES" -AutoUpdate:$False -ChocoGUI:$False
    Both -AutoUpdate and -ChocoGUI default to off; omitting them is equivalent
        to passing :$False as above.
    Parameters must be passed by NAME when calling the script directly:
        LocalRepository, DisableCommunityRepository, AutoUpdate and ChocoGUI are
        [Switch] parameters,
        which PowerShell never binds positionally, so the old positional form
        (./Chocolatey_Deploy $True "http://..." "NAME" $False) fails with
        "A positional parameter cannot be found that accepts argument 'NAME'".
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
            High Availability & Automatic Failover, Multi-Site Replication and AWS/Azure Package Cloud Storage.
.LINK
	https://github.com/gabriel-vanca/Chocolatey
.NOTES
	Author: Gabriel Vanca
#>

[CmdletBinding()]
param(
    [Switch]$LocalRepository,
    [String]$LocalRepositoryPath,
    [String]$LocalRepositoryName,
    [Switch]$DisableCommunityRepository,
    [Switch]$AutoUpdate,
    [Switch]$ChocoGUI
)

#Requires -RunAsAdministrator

# #Requires above is ignored when this script runs via [Scriptblock]::Create +
# Invoke-Command (the Chocolatey_Deploy.bat download fallback and the README's
# network snippet), so the privilege check must also be done manually.
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "This script requires administrator privileges. Run it from an elevated PowerShell session."
}

# TLS 1.3 exclusively on Windows 11 / Server 2022 and newer (build 20348+), TLS 1.2 on
# older Windows. Numeric values (12288 = Tls13, 3072 = Tls12) because the Tls13 enum
# name only resolves on .NET Framework 4.8+. Affects only this process's .NET
# downloads; choco.exe negotiates TLS in its own process.
if ([Environment]::OSVersion.Version.Build -ge 20348) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]12288
} else {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]3072
}

Write-Host "Running with the following parameters:"
Write-Host "LocalRepository: $LocalRepository"
if ($LocalRepository) {
    Write-Host "LocalRepositoryPath: $LocalRepositoryPath"
    Write-Host "LocalRepositoryName: $LocalRepositoryName"
    Write-Host "DisableCommunityRepository: $DisableCommunityRepository"
}
Write-Host "AutoUpdate: $AutoUpdate"
Write-Host "ChocoGUI: $ChocoGUI"
Write-Host "Starting proceedings"

# Expected path of the choco.exe file.
$chocoInstallPath = "$Env:ProgramData\chocolatey\choco.exe"
if (Test-Path "$chocoInstallPath") {
    # Return rather than throw: a throw is script-terminating for callers such as
    # Chocolatey_Demo.ps1. The existing installation is left untouched.
    Write-Warning "Chocolatey is already installed. Skipping deployment to avoid misconfiguring the existing installation."
    return
}

Write-Host "No existing Chocolatey installation found. Beginning installation."

Set-ExecutionPolicy Bypass -Scope Process -Force
try {
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} catch {
    throw "Downloading or running the Chocolatey installer failed: $($_.Exception.Message)"
}

# Verify before the environment refresh below, so a failed install produces one clear
# diagnostic instead of a cascade of secondary errors.
Write-Host "Testing that choco was installed..."
if (!(Test-Path "$chocoInstallPath")) {
    throw "Chocolatey installation failure"
}
& $chocoInstallPath --version
Write-Host "Chocolatey installation successful" -ForegroundColor DarkGreen

Write-Host "Refreshing terminal"
# Make `refreshenv` available right away, by defining the $env:ChocolateyInstall
# variable and importing the Chocolatey profile module. choco.exe's location was
# verified above, so the install root is known without relying on the installer
# having updated this process's PATH.
$env:ChocolateyInstall = "$Env:ProgramData\chocolatey"
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
# refreshenv is an alias of Update-SessionEnvironment; one call suffices.
Update-SessionEnvironment

$configurationFailed = $False

Write-Host "Configuring Chocolatey Sources"

# Auto confirm package installations (no need to pass -y)
choco feature enable -n allowGlobalConfirmation
# choco is a native exe: failures set $LASTEXITCODE and never throw (a try/catch
# cannot see them), so every choco call in this script is checked explicitly.
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Enabling the allowGlobalConfirmation feature failed with exit code $LASTEXITCODE."
    $configurationFailed = $True
}

function Write-RepositoryFailureBanner {
    param([string[]]$Messages)
    Write-Host "*****************************************************************" -ForegroundColor DarkRed
    foreach ($message in $Messages) {
        Write-Host $message -ForegroundColor DarkRed
    }
    Write-Host "*****************************************************************" -ForegroundColor DarkRed
}

# Configure Sources. Higher values means higher priority.
if ($LocalRepository) {
    Write-Host "Trying to use a local repository"
    if ([string]::IsNullOrEmpty($LocalRepositoryPath)) {
        Write-Error "The local repository path is null or empty."
        $LocalRepository = $False
        $configurationFailed = $True
    } elseif ([string]::IsNullOrEmpty($LocalRepositoryName)) {
        Write-Error "The local repository name is null or empty."
        $LocalRepository = $False
        $configurationFailed = $True
    } else {
        # Warn on cleartext HTTP: package payloads are then transferred unencrypted
        # and unverified, so anyone able to intercept the traffic could tamper with
        # them. On a trusted local LAN the practical risk is low, so this is a warning
        # rather than a hard failure. Prefer HTTPS where the repository supports it.
        if ($LocalRepositoryPath -match '^\s*http://') {
            Write-Warning "The local repository path uses insecure HTTP ($LocalRepositoryPath). Prefer HTTPS; on a trusted local LAN this risk is low."
        }
        choco source add -n $LocalRepositoryName -s $LocalRepositoryPath --priority=10
        if ($LASTEXITCODE -ne 0) {
            Write-RepositoryFailureBanner @(
                "Failed to add local repository '$LocalRepositoryName' ($LocalRepositoryPath).",
                "choco source add exit code: $LASTEXITCODE.",
                "Falling back to the Chocolatey Community Repository."
            )
            $LocalRepository = $False
            $configurationFailed = $True
        } else {
            Write-Host "Using Chocolatey local repository $LocalRepositoryName as main source."
            # "choco source add" does not test reachability; a typo or dead server
            # still succeeds here. Verify the source serves packages before disabling
            # the community repository across a fleet.
            if ($DisableCommunityRepository) {
                choco source disable -n=chocolatey
                if ($LASTEXITCODE -ne 0) {
                    Write-RepositoryFailureBanner @(
                        "Failed to disable the Chocolatey Community Repository.",
                        "choco source disable exit code: $LASTEXITCODE.",
                        "The Community Repository remains ENABLED."
                    )
                    $configurationFailed = $True
                } else {
                    Write-Host "Disabled Chocolatey Community Repository"
                }
            }
        }
    }
}

if (-not $LocalRepository) {
    Write-Host "Using Chocolatey Community Repository as main source."
    Write-Host "Note that if you have multiple machines/VMs running on your local network, `n     you will run into the Chocolatey Community Repository traffic limit." -ForegroundColor DarkYellow
}

Write-Host "Printing Chocolatey sources list:"
Write-Host "[START LIST]"
choco source list
Write-Host "[END LIST]"

# useRememberedArgumentsForUpgrades is deliberately NOT enabled: it would let upgrades
# reuse install-time arguments (issue #797), but it stays off until chocolatey/choco
# issues #2886 and #2761 and PR #3003 are resolved.


Write-Host "Configuring Chocolatey Package Cleaning" -ForegroundColor DarkBlue
# Set it and forget it! Choco-Cleaner cleans up your Chocolatey installation
# every Sunday at 11 PM in the background so you don't have to be bothered with it.
choco install choco-cleaner -y
# 1641 (reboot initiated) and 3010 (reboot required) are success exit codes for
# choco install: usePackageExitCodes (default on) lets package codes propagate.
if ($LASTEXITCODE -notin 0, 1641, 3010) {
    Write-Warning "Installing choco-cleaner failed with exit code $LASTEXITCODE. Package cache cleaning is NOT configured."
    $configurationFailed = $True
}


if ($AutoUpdate) {
    Write-Host "Configuring Chocolatey Updates" -ForegroundColor DarkBlue
    <#
     Creates a Windows Scheduled Task to run "choco upgrade all -y" with enhanced options at a time and frequency you specify
     And because sometimes package installations go wrong, it will also create a Windows Scheduled Task to
     run "taskkill /im choco.exe /f /t" to stop the Chocolatey (choco.exe) process and all child processes at a time you specify.
     Runs "choco upgrade all -y" daily at 3 AM and aborts it at 6 AM.
    #>
    choco install choco-upgrade-all-at -y --params "'/DAILY:yes /TIME:03:00 /ABORTTIME:06:00'"
    if ($LASTEXITCODE -notin 0, 1641, 3010) {
        Write-Warning "Installing choco-upgrade-all-at failed with exit code $LASTEXITCODE. Automatic updates are NOT configured."
        $configurationFailed = $True
    }
} else {
    Write-Host "AutoUpdate switch not set. Skipping automatic update configuration."
}


if ($ChocoGUI) {
    Write-Host "Installing and Configuring Chocolatey GUI" -ForegroundColor DarkBlue
    choco install chocolateygui -y --params "'/Global /ShowConsoleOutput=$true /PreventAutomatedOutdatedPackagesCheck=$true /DefaultToTileViewForLocalSource=$false /DefaultToTileViewForRemoteSource=$false /DefaultToDarkMode=$true'"
    if ($LASTEXITCODE -notin 0, 1641, 3010) {
        Write-Warning "Installing Chocolatey GUI failed with exit code $LASTEXITCODE."
        $configurationFailed = $True
    }
} else {
    Write-Host "ChocoGUI switch not set. Skipping Chocolatey GUI installation."
}

if ($configurationFailed) {
    Write-Warning "Chocolatey configuration completed WITH ERRORS. Review the warnings above."
} else {
    Write-Host "Chocolatey configuration completed."  -ForegroundColor DarkGreen
}
