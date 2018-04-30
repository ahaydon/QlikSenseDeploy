$password = ConvertTo-SecureString -String "Sense1234" -AsPlainText -Force
$SenseService = New-Object System.Management.Automation.PSCredential("$(hostname)\qservice", $password)
$QlikAdmin = New-Object System.Management.Automation.PSCredential("$(hostname)\qlik", $password)

$scriptpath = c:\vagrant\scripts\

. $scriptpath\SenseSetup.ps1

# Configuration Sense
# {
#   Import-DscResource -ModuleName PSDesiredStateConfiguration
#
#   Main QlikSense {
#     Hostname = $(hostname)
#     QlikAdmin = $QlikAdmin
#     SenseService = $SenseService
#     LicenseSerial = $ConfigurationData.NonNodeData.License.Serial
#     LicenseControl = $ConfigurationData.NonNodeData.License.Control
#     LicenseName = $ConfigurationData.NonNodeData.License.Name
#     LicenseOrg = $ConfigurationData.NonNodeData.License.Organization
#     # LicenseLef = $ConfigurationData.NonNodeData.License.Lef
#   }
# }

Main -ConfigurationData $scriptpath\ConfigData.psd1 -Hostname $(hostname) -QlikAdmin $QlikAdmin -SenseService $SenseService
Start-DscConfiguration -Path .\Main -Wait -Verbose -Force
