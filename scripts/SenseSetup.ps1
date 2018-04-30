Configuration Main
{
    Param (
        [string]$SenseSetupUri = "https://da3hntz84uekx.cloudfront.net/QlikSense/11.24/0/_MSI/Qlik_Sense_setup.exe",
        [string]$SenseUpdateUri = "https://da3hntz84uekx.cloudfront.net/QlikSense/11.24/1/_MSI/Qlik_Sense_update.exe",
        [string]$DownloadPath = $env:temp,
        [PSCredential]$SenseService,
        [Parameter(ParameterSetName="Central")]
        [PSCredential]$QlikAdmin,
        [string]$ClusterShareHost,
        [string]$Hostname,

        [Parameter(ParameterSetName="Central")]
        $LicenseSerial = $ConfigurationData.NonNodeData.License.Serial,
        [Parameter(ParameterSetName="Central")]
        $LicenseControl = $ConfigurationData.NonNodeData.License.Control,
        [Parameter(ParameterSetName="Central")]
        $LicenseOrg = $ConfigurationData.NonNodeData.License.Organization,
        [Parameter(ParameterSetName="Central")]
        $LicenseName = $ConfigurationData.NonNodeData.License.Name,
        [Parameter(ParameterSetName="Central", Mandatory=$false)]
        $LicenseLef = $ConfigurationData.NonNodeData.License.Lef,

        [Parameter(ParameterSetName="RimNode")]
        $CentralNode,
        [Parameter(ParameterSetName="RimNode")]
        [ValidateSet("Proxy", "Engine", "ProxyEngine", "Scheduler", "All")]
        $NodeType = "All"
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration, xPSDesiredStateConfiguration, QlikResources

    Node localhost
    {
        User QlikAdmin
        {
            UserName = $QlikAdmin.GetNetworkCredential().UserName
            Password = $QlikAdmin
            FullName = 'QlikAdmin'
            PasswordChangeRequired = $false
            PasswordNeverExpires = $true
            Ensure = 'Present'
        }

        User SenseService
        {
            UserName = $SenseService.GetNetworkCredential().UserName
            Password = $SenseService
            FullName = 'Qlik Sense Service Account'
            PasswordChangeNotAllowed = $true
            PasswordChangeRequired = $false
            PasswordNeverExpires = $true
            Ensure = 'Present'
        }

        Group Administrators
        {
            GroupName = 'Administrators'
            MembersToInclude = $QlikAdmin.GetNetworkCredential().UserName, $SenseService.GetNetworkCredential().UserName
        }

        File DownloadPath
        {
          Type = 'Directory'
          DestinationPath = Join-Path -Path $DownloadPath -ChildPath $Name
          Ensure = 'Present'
        }

        $SenseSetupPath = Join-Path -Path $DownloadPath -ChildPath $SenseSetupUri.Substring($SenseSetupUri.LastIndexOf('/') + 1)
        xRemoteFile SenseSetup
        {
          DestinationPath = $SenseSetupPath
          Uri = $SenseSetupUri
          MatchSource = $false
        }

        $SenseUpdatePath = Join-Path -Path $DownloadPath -ChildPath $SenseUpdateUri.Substring($SenseUpdateUri.LastIndexOf('/') + 1)
        xRemoteFile SenseUpdate
        {
          DestinationPath = $SenseUpdatePath
          Uri = $SenseUpdateUri
          MatchSource = $false
        }

		if ($PsCmdlet.ParameterSetName -EQ 'Central')
		{
			QlikCentral CentralNode
			{
				SenseService = $SenseService
				QlikAdmin = $QlikAdmin
				ProductName = "Qlik Sense November 2017 Patch 1"
				SetupPath = $SenseSetupPath
				PatchPath = $SenseUpdatePath
				Hostname = $Hostname
				ClusterShareHost = $ClusterShareHost
				License = @{
				  Serial = $LicenseSerial
				  Control = $LicenseControl
				  Name = $LicenseName
				  Organization = $LicenseOrg
				  Lef = $LicenseLef
				}
				PSDscRunasCredential = $QlikAdmin
			}
		}
		else
		{
			QlikRimNode $Hostname
			{
				SenseService = $SenseService
				QlikAdmin = $QlikAdmin
				ProductName = "Qlik Sense November 2017 Patch 1"
				SetupPath = $SenseSetupPath
				PatchPath = $SenseUpdatePath
				Hostname = $Hostname
				CentralNode = $CentralNode
				Proxy = (@('Proxy', 'ProxyEngine', 'All') -contains $NodeType)
				Engine = (@('Engine', 'ProxyEngine', 'Scheduler', 'All') -contains $NodeType)
				Printing = (@('Engine', 'ProxyEngine', 'All') -contains $NodeType)
				Scheduler = (@('Scheduler', 'All') -contains $NodeType)
				PSDscRunasCredential = $QlikAdmin
			}
		}
    }
}
