[CmdletBinding()]
param (
	[Parameter()]
	[string]
	$ControlFile
)

function SuccessMessage($message) {
	Write-Host "👌 $message" -ForegroundColor Green
}
function WarningMessage($message) {
	Write-Host "👆 $message" -ForegroundColor Yellow
}
function ErrorMessage($message) {
	Write-Host "🔥 $message" -ForegroundColor Red
}
function DebugMessage($message) {
	Write-Host $message -ForegroundColor Gray
}

# Check if we run elevated
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdminContext = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (!$isAdminContext) {
	ErrorMessage('Script needs to be run with admin privileges!')
	exit 1
}
SuccessMessage('Admin context enabled.')
# Check if parameter for file is present
if (!(Test-Path -Path $ControlFile)) {
	ErrorMessage("File '$ControlFile' not found.")
	exit 2
}
SuccessMessage('Settings file found.')
# Read the settings
$settings = Get-Content -Path $ControlFile -Raw | ConvertFrom-Json -Depth 10
# Install chocolatey if not present
Set-ExecutionPolicy Unrestricted -Scope CurrentUser
$choco = Get-Command choco
if (!$choco) {
	DebugMessage "Chocolatey not installed -> Installing..."	
	Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
	SuccessMessage("Chocolatey installed.")
	# reset the paths
	$env:Path = [System.Environment]::ExpandEnvironmentVariables([System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User"))
	$choco = Get-Command choco
	if (!$choco) {
		# choco was installed but now after reloading the environment settings for the path we cannot find it
		WarningMessage("Installation ran but choco was not found in path. Maybe re-run the script?")
		exit 3
	}
} else {
	# choco was found in the first try
	DebugMessage("Chocolatey found in $($choco.Source)")
}
# Run first tranch

# Reboot with autostart
