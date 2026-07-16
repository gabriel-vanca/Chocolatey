# Chocolatey

A guided script to install and configure [Chocolatey](https://chocolatey.org/) and deploy packages with it, on both Windows client and Windows Server.

![Windows 10](https://img.shields.io/badge/Windows%2010-tested-2ea44f?logo=windows)
![Windows 11](https://img.shields.io/badge/Windows%2011-tested-2ea44f?logo=windows11)
![Windows Sandbox](https://img.shields.io/badge/Windows%2011%20Sandbox-tested-2ea44f?logo=windows11)
![Server 2019](https://img.shields.io/badge/Server%202019-tested-2ea44f?logo=windowsserver)
![Server 2022](https://img.shields.io/badge/Server%202022-tested-2ea44f?logo=windowsserver)
![Server 2025](https://img.shields.io/badge/Server%202025-tested-2ea44f?logo=windowsserver)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)

---

## 📖Table of Contents <!-- omit from toc -->

- [⚒️Step 1: Deploy Chocolatey](#️step-1-deploy-chocolatey)
  - [What the script does](#what-the-script-does)
  - [📦Script Parameters](#script-parameters)
  - [🌐Deploy Script via Network](#deploy-script-via-network)
- [🔐Step 2: Deploy Local Chocolatey Repository (Optional)](#step-2-deploy-local-chocolatey-repository-optional)
- [🚇Step 3: Deploy Packages (Optional Demonstration)](#step-3-deploy-packages-optional-demonstration)
- [⚠️Troubleshooting](#️troubleshooting)
  - [⚠️ A. Running scripts is disabled on this system](#️-a-running-scripts-is-disabled-on-this-system)
  - [⚠️ B. Script is blocked](#️-b-script-is-blocked)

---

## ⚒️Step 1: Deploy Chocolatey

Run the deploy script from an elevated PowerShell session:

```powershell
./Chocolatey_Deploy
```

Alternatively, **double-click `Chocolatey_Deploy.bat`**. It self-elevates via a UAC prompt, bypasses execution-policy restrictions, and runs the local `Chocolatey_Deploy.ps1` (or downloads it from GitHub when used as a standalone single file on a bare machine). The parameters below (including `AutoUpdate` and `ChocoGUI`) are set by editing the `Place Arguments here` section at the top of the `.bat` file.

### What the script does

1. Checks whether Chocolatey is already installed.
   - If it is, deployment is skipped and the existing installation is left untouched.
2. Installs Chocolatey if it isn't present yet.
3. Verifies the installation succeeded.
4. Configures the default repository from the parameters below.
5. Installs a package cache cleaning utility.
6. Sets an auto-update configuration (only with `-AutoUpdate`).
7. Installs the Chocolatey GUI tool (only with `-ChocoGUI`).

### 📦Script Parameters

The script accepts six optional parameters. All must be passed by name.

| Parameter | Type | Description |
| --- | --- | --- |
| `-LocalRepository` | Switch | Enables a local repository. Omit to use the Chocolatey Community Repository. |
| `-LocalRepositoryPath` | String | Full FQDN or IP, port and path of the local repository. |
| `-LocalRepositoryName` | String | Name of the local repository. |
| `-DisableCommunityRepository` | Switch | Disables the Community Repository entirely. Only takes effect once a valid local repository has been added. Usually unnecessary unless you are specifically concerned about the security of packages from outside your organisation. |
| `-AutoUpdate` | Switch | Sets up automatic daily package updates via a scheduled task (`choco upgrade all` at 3 AM, aborted at 6 AM if still running). Off by default. |
| `-ChocoGUI` | Switch | Installs the [Chocolatey GUI](https://docs.chocolatey.org/en-us/chocolatey-gui/) tool. Off by default. |

> [!NOTE]
> Using the Community Repository can run you into traffic limits in a multi-machine deployment scenario. A local repository (see [Step 2](#step-2-deploy-local-chocolatey-repository-optional)) avoids that.

**Examples:**

```powershell
./Chocolatey_Deploy -LocalRepository -LocalRepositoryPath "http://10.10.10.1:8624/nuget/Thoth/" -LocalRepositoryName "THOTH" -AutoUpdate:$False -ChocoGUI:$False
```

```powershell
./Chocolatey_Deploy -LocalRepository -LocalRepositoryPath "http://hercules.cerberus.local:8624/nuget/Hercules/" -LocalRepositoryName "HERCULES" -AutoUpdate:$False -ChocoGUI:$False
```

> [!NOTE]
> The exact port and path form for the local repository depend on the repository software you are using. `-AutoUpdate` and `-ChocoGUI` default to off; omitting them is equivalent to passing `:$False` as above.

> [!IMPORTANT]
> Parameters must be passed **by name**, as shown above. `-LocalRepository`, `-DisableCommunityRepository`, `-AutoUpdate` and `-ChocoGUI` are `[Switch]` parameters, which PowerShell never binds positionally, so the old positional form (`./Chocolatey_Deploy $True "http://..." "THOTH" $False`) fails with `A positional parameter cannot be found that accepts argument 'THOTH'`.

### 🌐Deploy Script via Network

To install and configure Chocolatey without downloading the repo, run the following from an **elevated (administrator)** PowerShell session:

```powershell
$scriptPath = "https://raw.githubusercontent.com/gabriel-vanca/Chocolatey/main/Chocolatey_Deploy.ps1"
$WebClient = New-Object Net.WebClient
$deploymentScript = $WebClient.DownloadString($scriptPath)
$deploymentScript = [Scriptblock]::Create($deploymentScript)

# Parameters, splatted so every switch is named. Defaults below are:
# Chocolatey Community Repository, no auto-update, no GUI.
$deployArgs = @{
    LocalRepository            = $False
    LocalRepositoryPath        = ""
    LocalRepositoryName        = ""
    DisableCommunityRepository = $False
    AutoUpdate                 = $False
    ChocoGUI                   = $False
}

# Default: deploy with the settings above
. $deploymentScript @deployArgs
```

```powershell
# Or, to use a local repository, change only the source fields first:
$deployArgs.LocalRepository     = $True
$deployArgs.LocalRepositoryPath = "http://10.10.10.1:8624/nuget/Thoth/"
$deployArgs.LocalRepositoryName = "THOTH"

. $deploymentScript @deployArgs
```

> [!NOTE]
> Dot-sourcing (`. $deploymentScript`) runs the script in the current session, so `choco` is available immediately afterward, and splatting `@deployArgs` binds every parameter **by name**, so you never have to remember positional order. The script checks for administrator privileges itself and refuses to run unelevated.

---

## 🔐Step 2: Deploy Local Chocolatey Repository (Optional)

Using the Community Repository can run you into traffic limits in a multi-machine deployment scenario. For that reason, as well as security, licensing and IP protection, you might decide to deploy your own local Chocolatey repository.

The examples above use [Inedo ProGet](https://inedo.com/proget) free software.

- Deployable on Windows (including Windows Server with a free ProGet license) and on Linux Docker containers.
- Packages can be stored locally or on an SMB/NFS network share.
  - ⚠️ Make sure sufficient storage is available.
- ProGet can install its own SQL Express database, or use an external SQL database such as the free edition of Microsoft SQL Server.
- Paid ProGet editions add retention policies, LDAP/AD integration, load balancing, high availability and automatic failover, multi-site replication, and AWS/Azure package cloud storage.

---

## 🚇Step 3: Deploy Packages (Optional Demonstration)

This step is entirely optional. It demonstrates how Chocolatey can deploy packages once Steps 1 and 2 are done, and how to connect to a local repository if one is present. The demo files live in the `Demo` directory:

```powershell
./Demo/Chocolatey_Demo
```

Alternatively, double-click `Demo\Chocolatey_Demo.bat`. It unblocks the repo files and self-elevates via a UAC prompt before running the demo script.

The demo script will:

1. Install and configure Chocolatey using the deploy script from Step 1 (skipped automatically if Chocolatey is already installed).
2. Connect it to a local repository, if indicated in the prompts.
3. Set up automatic daily updates and install the Chocolatey GUI, if indicated in the prompts.
4. Install a set of "Core" apps (zip archiver, git, Dropbox, etc.), including OS-purpose-selected (consumer vs Server) packages.
5. Install a set of apps dedicated to Server, NAS, Workstation, Laptop or Gaming, depending on the environment selected during the demo prompts.

> [!WARNING]
> `Chocolatey_Demo.ps1` is **purely for demonstration**: it shows how to install and configure Chocolatey with the deploy script (`Chocolatey_Deploy.ps1`) and then use Chocolatey to install software. You HAVE TO download and configure `Chocolatey_Demo.ps1` as you require it, or fork the repo and edit it as needed.

---

## ⚠️Troubleshooting

### ⚠️ A. Running scripts is disabled on this system

You might encounter this error on a Windows 10/11 system:

> *C:\temp\.\Script.ps1 cannot be loaded because running scripts is disabled on this system. For more information, see about_Execution_Policies at <https://go.microsoft.com/fwlink/?LinkID=135170>*

Fix it by setting the execution policy:

```powershell
Set-ExecutionPolicy RemoteSigned
```

`RemoteSigned` is the default policy on Windows Server deployments.

- It requires a digital signature from a trusted publisher on scripts and configuration files downloaded from the internet.
- It does not require signatures on scripts written on the local computer. Any unblocked script downloaded from the internet is treated as a local script and therefore needs no trusted signature.

You also need to unblock any scripts you are running (see below). This is only necessary if you download the files directly from GitHub through a web browser. The `Deploy Script via Network` method above does not mark scripts as blocked, and neither does copy-pasting a script into your terminal.

Alternatively, set the execution policy to `Bypass` for the current terminal session only. This does not block anything in the current shell and therefore requires no unblocking:

```powershell
Set-ExecutionPolicy Bypass -Scope Process
```

### ⚠️ B. Script is blocked

Files downloaded from the internet via a web browser are typically marked as blocked, which means the `RemoteSigned` policy expects them to be signed. Unblocking them makes them behave like locally written scripts, requiring no trusted signature.

The best approach is to unblock the `.zip` archive immediately after downloading and **before** extraction:

```powershell
Unblock-File -Path "D:\Downloads\Chocolatey.zip"
```

Alternatively, unblock the files recursively after extraction:

```powershell
Get-ChildItem "D:\Downloads\Chocolatey" -recurse | Unblock-File
```

You can also unblock the archive or extracted files from the **Properties** menu by ticking **Unblock** and clicking **OK** or **Apply**:

<p align="center">
  <img src="image/README/1692737295733.png" alt="Unblock a file from its Properties menu">
</p>
