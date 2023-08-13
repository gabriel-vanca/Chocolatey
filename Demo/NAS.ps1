Write-Host "Installing Disk Management tools"
choco install linkshellextension -y
choco install partitionmasterfree -y
choco install crystaldiskinfo -y
choco install crystaldiskmark -y
choco install seatools -y
choco install smartmontools -y

Write-Host "Installing Data Transfer tools"
choco install resilio-sync-home -y

Write-Host "Installing Data Monitoring tools"
choco install gdu -y

Write-Host "Installing Veeam backup tools"
choco install veeam-backup-and-replication-server -y

Write-Host "Installing Content Acquiring software"
choco install prowlarr -y
choco install sonarr -y # Installs as service
choco install radarr -y # Installs as service
choco install lidarr -y

Write-Host "Installing Content Delivery software"
choco install plexmediaserver  -y
choco install calibre -y
