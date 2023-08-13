Write-Host "Installing Data Monitoring tools"
choco install gdu -y

Write-Host "Installing Veeam backup Extract Utility"
choco install veeam-backup-and-replication-extract -y

Write-Host "Installing Content Encoding software"
choco install makemkv -y
choco install staxrip -y
choco install subtitleedit -y
choco install mkvtoolnix -y

Write-Host "Installing SQL Server"
choco install sql-server-2019 -y