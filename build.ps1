Import-Module PowerShellGet

#Publish to PSGallery and install/import locally

Publish-Module -Path .\MSSQLManagementPowerShell -Repository PSGallery -Verbose
Install-Module -Name MSSQLManagementPowerShell -Repository PSGallery -Force
Import-Module -Name MSSQLManagementPowerShell -Force