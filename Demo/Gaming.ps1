Write-Host "Installing Drivers"

Write-Host "Installing AMD Ryzen/Threadripper Chipset (Desktop/Mobile) (with/without with Radeon Graphics)"
choco install amd-ryzen-chipset -y
choco install amd-ryzen-master -y

choco install geforce-experience -y --pin
choco install msiafterburner -y
choco install icue -y

Write-Host "Installing Storage Drivers"
choco install samsung-nvme-driver -y
choco install samsung-magician -y --ignore-checksums

Write-Host "Installing Peripherals Drivers"
choco install lghub -y --ignore-checksums --pin

Write-Host "Installing Driver Managers"
choco install intel-dsa -y --ignore-checksums

Write-Host "Installing Gaming software"
choco install steam-client -y
choco install ubisoft-connect -y
choco install epicgameslauncher -y
choco install playnite -y
choco install gamesavemanager -y
choco install nmm -y  #Nexus Mod Manager

Write-Host "Installing Communication Tools"
choco install discord -y
