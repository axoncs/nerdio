#description: Install the Conenctwise Control Agent.
#execution mode: Individual
#tags: Axon, Connectwise Control

<#
Notes:
The installation script requires an account key and an organization key, 
which are used to associate the agent with a specific organization 
within the Huntress partner account. 
You must provide secure variables to this script as seen in the Required Variables section. 
Set these up in Nerdio Manager under Settings->Portal. The variables to create are:
    
	CWCFQDN - This is the fqdn used to access Connectwise Control
	CWCHost - This is the h= in your MSI URL
	CWCPort - This is the p= in your MSI URL
	CWCKey - This is the k= in your MSI URL
	CWCClient
		
#>

##### Required Variables #####

$fqdn = $SecureVars.CWCFQDN
$host = $SecureVars.CWCHost
$portHost = $SecureVars.CWCPort
$key = $SecureVars.CWCKey
$client = $SecureVars.CWCClient

##### Script Logic #####

if(($Client -eq $null)) {
    Write-Output "ERROR: The secure variables CWCClient is not provided"
}

else {    
    $InstallerName   = "ConnectWiseControl.ClientSetup.msi"
    $InstallerPath = Join-Path $Env:TMP $InstallerName
    $DownloadURL     = "https://" + $url + "/Bin/ConnectWiseControl.ClientSetup.msi?h=" + $host + "&p=" + $port + "&k=" + $key + "&e=Access&y=Guest&t=&c=" + $client + "&c=&c=&c=&c=&c=&c=&c="
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($DownloadURL, $InstallerPath)
    Start-Process $InstallerPath -wait -ArgumentList '/qn /norestart' -PassThru
} 