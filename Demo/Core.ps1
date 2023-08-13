Write-Host "Installing common tools for all machine types"

choco install whocrashed -y --ignore-checksums
choco install micro -y
choco install regcool -y --ignore-checksums
choco install openssh -y
choco install powertoys -y
choco install peazip.install -y
choco install nerd-fonts-firacode -y


$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
if($osInfo.ProductType -eq 1) {
    Write-Host "Windows 10/11 deployment detected" -ForegroundColor DarkYellow
    Write-Host "Installing Windows consumer specific tools"

    Write-Host "Installing Cloud and File transfer software"
    choco install dropbox -y
    choco install resilio-sync-home -y

    Write-Host "Installing Content Delivery software"
    choco install plex -y
    choco install plexamp -y

    Write-Host "Installing Communication Tools"
    choco install whatsapp -y

} else {

    Write-Host "Windows Server deployment detected" -ForegroundColor DarkYellow
    Write-Host "Installing Windows Server specific tools"

    choco upgrade microsoft-vclibs -y
    choco upgrade winget-cli -y
    choco upgrade powershell-core -y --install-arguments='"ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1"' --packageparameters '"/CleanUpPath"' #Pre-Installed in Windows 11
    choco upgrade microsoft-windows-terminal -y
    choco install path-copy-copy -y
    choco install teracopy -y
}

choco install git -y --params "/WindowsTerminal /NoShellIntegration"