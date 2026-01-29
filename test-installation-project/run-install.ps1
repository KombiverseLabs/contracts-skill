# Test installation script
# Run this to test the installation in the test-installation-project folder

$ErrorActionPreference = 'Stop'

# Get the script's directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import and run the installer
. (Join-Path $scriptDir '..\installers\install.ps1')
Install-ContractsSkill -Scope project
