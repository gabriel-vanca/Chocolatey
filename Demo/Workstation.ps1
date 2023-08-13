Write-Host "Installing Disk Management tools"
choco install linkshellextension -y

Write-Host "Installing Data Monitoring tools"
choco install treesizefree -y

Write-Host "Installing Version Control tools"
choco install github-desktop -y
choco install gitkraken -y
choco install repoz -y

Write-Host "Installing Productivity & Research Tools"
choco install grammarly-for-windows -y --ignore-checksums
choco install notion -y  --pin
choco install xmind-2020 -y
choco install monday -y

Write-Host "Installing browsers"
choco install firefox -y

Write-Host "Installing Communication Tools"
choco install slack -y
choco install zoom -y


Write-Host "Installing VS Code"
choco install vscode -y --params "/NoDesktopIcon" #This is a system-wide installation

Write-Host "Refreshing terminal"
# Make `refreshenv` available right away, by defining the $env:ChocolateyInstall
# variable and importing the Chocolatey profile module.
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."   
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
Update-SessionEnvironment
refreshenv

Write-Host "Installing VS Code extensions"
code --install-extension GitHub.github-vscode-theme
code --install-extension aaron-bond.better-comments
code --install-extension alefragnani.Bookmarks
