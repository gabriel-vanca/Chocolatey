# Chocolatey

This is a guided script to install and config chocolatey and deploy packages with chocolatey.

🪟This deployment solution was tested on:

* ✅Windows 10
* ✅Windows 11
* ✅Windows 11 Sandbox
* ✅Windows Server 2019
* ✅Windows Server 2022
* ✅Windows Server 2025

## ⚒️Step 1: Deploy Chocolatey

```powershell
./Chocolatey_Deploy
```

Alternatively, double-click `Chocolatey_Deploy.bat`: it self-elevates via a UAC prompt, bypasses execution-policy restrictions, and runs the local `Chocolatey_Deploy.ps1` (or downloads it from GitHub when used as a standalone single file on a bare machine).

The script does the following:

  1. Checks whether chocolatey is already installed.
      * Skips deployment if it is, leaving the existing installation untouched.
  2. If it isn't installed yet, it installs chocolatey.
  3. Verifies if installation has been successful
  4. Configures the default repository as per set parameters (see below)
  5. Sets an auto-update configuration
  6. Installs a package cache cleaning utility
  7. Installs the Chocolatey GUI tool

### 📦Custom Source Settings

The script comes with 4 optional parameters:

* LocalRepository
  * (Optional)
  * Enables a local repository.
  * Leave blank to use the Chocolatey Community Repository.
  * Note that using the Community Repository can run you into traffic limits in a multi-machine deployment scenario.
* LocalRepositoryPath
  * (Optional)
  * Specifies the full FQDN or IP, port and path of the local repository.
* LocalRepositoryName
  * (Optional)
  * Specifies the name of the local repository.
* DisableCommunityRepository
  * (Optional)
  * Allows disabling the Community Repository entirely.
  * This will only work if a valid local repository has been added.
  * Usually there should be no need to use this unless you're specifically concerned about the security of packages from outside your organisation.

Examples of how to run the script with custom source settings:

```powershell
./Chocolatey_Deploy -LocalRepository -LocalRepositoryPath "http://10.10.10.1:8624/nuget/Thoth/" -LocalRepositoryName "THOTH"
```

OR

```powershell
./Chocolatey_Deploy -LocalRepository -LocalRepositoryPath "http://hercules.cerberus.local:8624/nuget/Hercules/" -LocalRepositoryName "HERCULES"
```

> [!NOTE]
> The exact port and form of the path for the local repository will depend on the repository software you are using.
-----
> Note: the parameters must be passed by name, as shown. `LocalRepository` and `DisableCommunityRepository` are `[Switch]` parameters, which PowerShell never binds positionally, so the old positional form (`./Chocolatey_Deploy $True "http://..." "THOTH" $False`) fails with `A positional parameter cannot be found that accepts argument 'THOTH'`.

### 🌐Deploy Script via Network

If you want to quickly get Chocolatey installed and configured without downloading the script, run the below commands from an elevated (administrator) PowerShell session to download and run the script:

```powershell
$scriptPath = "https://raw.githubusercontent.com/gabriel-vanca/Chocolatey/main/Chocolatey_Deploy.ps1"
$WebClient = New-Object Net.WebClient
$deploymentScript = $WebClient.DownloadString($scriptPath)
$deploymentScript = [Scriptblock]::Create($deploymentScript)
Invoke-Command -ScriptBlock $deploymentScript -ArgumentList ($False, "", "", $False) -NoNewScope
```

> Note: `-ArgumentList` binds the scriptblock's parameters strictly positionally (switches included), so keep the argument order matching the script's `param()` block: LocalRepository, LocalRepositoryPath, LocalRepositoryName, DisableCommunityRepository. The script checks for administrator privileges itself and refuses to run unelevated.

### ⚠️Troubleshooting: Running Scripts is Disabled

You might encounter the following error on Windows 10/11 system:

> *C:\temp\.\Script.ps1 cannot be loaded because running scripts is disabled on this system. For more information, see about_Execution_Policies at <https://go.microsoft.com/fwlink/?LinkID=135170>*

Run the following to solve this problem:

```powershell
Set-ExecutionPolicy RemoteSigned
```

The `RemoteSigned` execution policy is the default policy on Windows Server deployments.

* It requires a digital signature from a trusted publisher on scripts and configuration files that are downloaded from the internet.
* It doesn't require digital signatures on scripts that are written on the local computer and not downloaded from the internet. Any unblocked scripts downloaded from the internet are treated as local scripts and therefore do not require a trusted signature.

You will need to also make sure you have unblocked any scripts you are running (see below instructions on how to do that). This is only necessary if you download the files directly from GitHub through a web browser. Using the `Deploy Script via Network` method above does not mark the scripts downloaded from GitHub as blocked. Same is true if you just copy+paste the script into your terminal window.

Alternatively, you can set your execution policy temporarily to Bypass for the current terminal session. This will not block anything that runs in the current shell session and therefore will not require you to unblock anything.

```powershell
Set-ExecutionPolicy Bypass -Scope Process
```

### ⚠️Troubleshooting: Script is Blocked

Files downloaded from the internet via a web browser are typically marked as blocked. That means that the RemoteSigned execution policy will expect them to be signed in order for them to be run. However, by unblocking them, they will be treated as scripts written locally and therefore not requiring a trusted signature.

The best method to unblock the files is by unblocking the .zip archive immediately after downloading it from GitHub and before extraction:

```powershell
Unblock-File -Path "D:\Downloads\Chocolatey.zip"
```

Alternatively, you can unblock the files after extraction recursively:

```powershell
Get-ChildItem "D:\Downloads\Chocolatey" -recurse | Unblock-File
```

You can also unblock the archives/the extracted files from the Properties menu by ticking the Unblock option and clicking OK or Apply:

![1692737295733](image/README/1692737295733.png)

## 🔐Step 2: Deploy Local Chocolatey Repository (Optional)

Using the Community Repository can run you into traffic limits in a multi-machine deployment scenario.

For that reason, as well as security, licensing and IP protection, you might decide to deploy your own local Chocolatey repository.

In the examples above, the repository software used is the Inedo ProGet free software.

* <https://inedo.com/proget>
* Inedo ProGet can be deployed on Windows (including Windows Server with a free ProGet license), as well as Linux Docker containers.
* The packages can be stored locally or on an SMB/NFS network share.
  * ⚠️Please make sure sufficient storage is available.
* ProGet can install its own SQL Express database, or be configured with an external SQL database such as the free edition of Windows SQL Server.
* The paid Inedo ProGet versions also support retention policies, LDAP/AD Integration, Load Balancing, High Availability & Automatic Failover, Multi-Site Replication and AWS/Azure Package Cloud Storage.

## 🚇Step 3: Deploy Packages using Chocolatey (Optional / Demonstration)

This step is entirely optional: it is a demonstration of how Chocolatey can be used to deploy packages once Steps 1 and 2 are done. A demo .ps1 script has been included with this project to showcase how Chocolatey can be used to deploy packages, as well as how to connect to a local repository if one is present. The demo files live in the `Demo` directory:

```powershell
./Demo/Chocolatey_Demo
```

Alternatively, double-click `Demo\Chocolatey_Demo.bat`: it unblocks the repo files and self-elevates via a UAC prompt before running the demo script.

The demo script will:

1. Install and configure Chocolatey using the deploy script from Step 1
   * skipped automatically if Chocolatey is already installed
2. Connect it to a local repository if so indicated in the prompts
3. Installs a set of "Core" apps (zip archiver, git, dropbox etc), including as set of OS-purpose-selected (consumer vs Server) packages
4. Installs a set dedicated apps for Server/NAS/Workstation/Laptop/Gaming, depending on the environment selected during the demo prompts.

⚠️REMINDER: The Chocolatey_Demo.ps1 is a demo script of how to install and configure Chocolatey using the deploy script (Chocolatey_Deploy.ps1) and then use Chocolatey to install software. You HAVE TO download and configure Chocolatey_Demo.ps1 as you require it or fork the repo and edit as needed. Chocolatey_Demo.ps1 is purely for demonstrative purposes. ⚠️
