# winrm-setup.ps1 - Run this script on the Windows machine to enable WinRM
# Execute as Administrator: powershell -ExecutionPolicy Bypass -File winrm-setup.ps1

Write-Host "Enabling WinRM..." -ForegroundColor Green

# Enable PowerShell Remoting
Enable-PSRemoting -Force -SkipNetworkProfileCheck

# Enable WinRM Quick Config
winrm quickconfig -q

# Allow unencrypted connections
winrm set winrm/config/service '@{AllowUnencrypted="true"}'

# Enable Basic authentication
winrm set winrm/config/service/auth '@{Basic="true"}'

# Enable remote shell access
winrm set winrm/config/winrs '@{AllowRemoteShellAccess="true"}'

# Open firewall port 5985
netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985

# Ensure WinRM service is running
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM

Write-Host "WinRM configured successfully!" -ForegroundColor Green
Write-Host "Test: ansible windows_hosts -m ansible.windows.win_ping" -ForegroundColor Yellow
