Write-Host "Installing Cloudflare free VPN"
choco install warp -y

Write-Host "Installing Communication Tools"
choco install zoom -y

Write-Host "Installing Management tools"

Write-Host "Installing Veeam Backup Console"
choco install veeam-backup-and-replication-console -y

Write-Host "Installing Veeam Backup Extract Utility"
choco install veeam-backup-and-replication-extract -y

Write-Host "Installing SQL Server management tool"
choco install sql-server-management-studio -y