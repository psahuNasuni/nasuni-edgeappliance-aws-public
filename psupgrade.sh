#!/bin/bash
# Retrieve the version of PowerShell
powershell_version=$(pwsh -Command '$PSVersionTable.PSVersion.Major')

# Format the output as a floating-point integer
psversion=$(printf "%.0f" $powershell_version)

installPwsh()
{
    Install-Module -Name PowerShell -RequiredVersion 6.0.0 -Force
}
# Check if PowerShell is installed
if [ $psversion == "" ]
then
  echo "PowerShell is not installed. Installing PowerShell..."
  # Install PowerShell
  installPwsh
# Check if the installed version of PowerShell is below 6
elif [ $psversion -lt 6 ]
then
  echo "PowerShell version is below 6. Upgrading to version 6 or above..."
  # Upgrade PowerShell to version 6 or above
  installPwsh
else 
  echo "PowerShell version is" $psversion". No upgrades necessary."
fi