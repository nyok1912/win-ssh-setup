# Handle input parameters
param (
	[string]$user,
	[string]$pass
)
$script:user = $user
$script:pass = $pass

# Set console color
$host.UI.RawUI.ForegroundColor = 'Cyan'
$host.UI.RawUI.BackgroundColor = 'Black'
Clear-Host

$ScriptURL = "https://raw.githubusercontent.com/nyok1912/win-ssh-setup/main/setup.ps1"

# Ensure if script is running as administrator
try {
	$isAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
	if (-not $isAdmin) {
		throw "ERROR: Run The Script As Administrator."
	}
} catch {
	Write-Host "============================================================"
	Write-Host "ERROR: Run the script as Administrator."
	Write-Host "============================================================"
	Write-Host ""
	Read-Host "Press any key to exit..."
	exit
}


# Function to request credentials if they are not passed as parameters
function Request-Credentials {
	clear
	$script:user = $null
	$script:pass = $null
	Write-Host "`nChoose username and password..."
	if (-not $script:user) {
		$script:user = Read-Host "Enter UserName"
	}
	if (-not $script:pass) {
		$script:pass = Read-Host "Enter Password"
	}

	if (-not $script:user -or -not $script:pass) {
		Request-Credentials
	} else {
		Show-Confirm
	}
}

function Show-Confirm {
	Write-Host "`nSelected name: '$script:user' and password: '$script:pass'"
	$confirm = Read-Host "Continue? (Y/n)"
	if ($confirm -ieq "N") {
		Request-Credentials
	}
}

# Ensure the variables are set and then display them
if ($script:user -and $script:pass) {
	Show-Confirm
} else {
	Write-Host "`nERROR: Missing UserName or Password"
	Request-Credentials
}

clear

# 1. Install the OpenSSH server
try {
	Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
	Write-Host "OpenSSH server installed successfully."
} catch {
	Write-Host "ERROR: Failed to install OpenSSH server."
	Write-Host "Details: $($_.Exception.Message)"
	Pause
	exit 1
}

# 2. Enable and configure the SSH service to start automatically
try {
	Start-Service -Name sshd
	Set-Service -Name sshd -StartupType 'Automatic'
	Write-Host "SSH service enabled and configured to start automatically."
} catch {
	Write-Host "ERROR: Failed to enable and configure SSH service."
	Write-Host "Details: $($_.Exception.Message)"
	Pause
	exit 1
}

# 3. Check if the user already exists
$adminGroupName = 'Administrators'
if (-not (Get-LocalGroup -Name $adminGroupName -ErrorAction SilentlyContinue)) {
	$adminGroupName = 'Administradores'
}
if (-not (Get-LocalGroup -Name $adminGroupName)) {
	Write-Host "ERROR: Administrators group not found."
	exit 1
}

$UserExists = Get-LocalUser | Where-Object { $_.Name -eq $script:user }
if (-not $UserExists) {
	try {
		Write-Host "Trying to make pass."
		$SecPassword = ConvertTo-SecureString $script:pass -AsPlainText -Force
		Write-Host "Pass created successfully: $SecPassword."
		New-LocalUser $script:user -Password $SecPassword -FullName 'SSH Admin User' -Description 'User for SSH access only'
		Write-Host "User $script:user created successfully."
		Add-LocalGroupMember -Group $adminGroupName -Member $script:user
		Write-Host "User $script:user added to group $adminGroupName successfully."
	} catch {
		Write-Host "ERROR: Failed to create user $script:user."
		Write-Host "Details: $($_.Exception.Message)"
		Pause
		exit 1
	}
} else {
	Write-Host "User $script:user already exists."
}

$remoteDesktopGroup = Get-LocalGroup | Where-Object { $_.Name -eq 'Remote Desktop Users' -or $_.Name -eq 'Usuarios de escritorio remoto' }
if (-not $remoteDesktopGroup) {
	Write-Host "WARNING: Remote Desktop group not found."
} else {
	$remoteDesktopGroupName = $remoteDesktopGroup.Name
	Add-LocalGroupMember -Group $remoteDesktopGroupName -Member $script:user
	Write-Host "User $script:user added to group $remoteDesktopGroupName successfully."
}

# 4. Ensure the registry key exists and hide the user from the local login screen
try {
	$RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
	if (-not (Test-Path $RegistryPath\SpecialAccounts)) {
		New-Item -Path $RegistryPath -Name 'SpecialAccounts' -Force | Out-Null
	}
	if (-not (Test-Path $RegistryPath\SpecialAccounts\UserList)) {
		New-Item -Path $RegistryPath\SpecialAccounts -Name 'UserList' -Force | Out-Null
	}
	$UserHidden = Get-ItemProperty -Path $RegistryPath\SpecialAccounts\UserList | Select-Object -ExpandProperty $script:user -ErrorAction SilentlyContinue
	if (-not $UserHidden) {
		New-ItemProperty -Path $RegistryPath\SpecialAccounts\UserList -Name $script:user -Value 0 -PropertyType DWORD -Force
		Write-Host "User $script:user hidden from the login screen."
	} else {
		Write-Host "User $script:user is already hidden."
	}
} catch {
	Write-Host "ERROR: Failed to configure the registry for user $script:user."
	Write-Host "Details: $($_.Exception.Message)"
	Pause
	exit 1
}

# 5. Configure the sshd_config file to allow only the specified user for SSH access
try {
	$sshdConfigPath = 'C:\ProgramData\ssh\sshd_config'
	if (-not (Test-Path $sshdConfigPath)) { Out-File -FilePath $sshdConfigPath }
	$sshdConfigContent = Get-Content -Path $sshdConfigPath
	if (-not ($sshdConfigContent -contains "AllowUsers $script:user")) {
		Add-Content -Path $sshdConfigPath -Value "AllowUsers $script:user"
		Write-Host "SSH configuration updated to allow only $script:user access."
	} else {
		Write-Host "SSH configuration already allows $script:user access."
	}
} catch {
	Write-Host "ERROR: Failed to configure sshd_config."
	Write-Host "Details: $($_.Exception.Message)"
	Pause
	exit 1
}

# 6. Restart the SSH service to apply changes
try {
	Restart-Service -Name sshd
	Write-Host "SSH service restarted."
} catch {
	Write-Host "ERROR: Failed to restart SSH service."
	Write-Host "Details: $($_.Exception.Message)"
	Pause
	exit 1
}

# Obtener las direcciones IP locales IPv4
$ips = Get-NetIPAddress -AddressFamily IPv4

# Filtrar y mostrar las direcciones IP
Write-Host "Direcciones IPv4 disponibles:"
foreach ($ip in $ips) {
	# Filtrar solo direcciones IP que no sean de loopback y no estén en estado 'deprecated'
	if ($ip.AddressState -eq 'Preferred') {
		$currip = $ip.IPAddress;
		if (![string]::IsNullOrWhiteSpace($currip)) {
			Write-Host "You can test SSH connection now using: ssh $script:user@$currip"
		}
	}
}

# Pause script
Read-Host "Press Enter to exit..."
