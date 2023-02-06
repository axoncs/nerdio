#description: Install the Datto RMM Agent.
#execution mode: Individual
#tags: Axon, Datto, RMM

<#
Notes:
The installation script requires an account key and an organization key, 
which are used to associate the agent with a specific organization 
within the Huntress partner account. 
You must provide secure variables to this script as seen in the Required Variables section. 
Set these up in Nerdio Manager under Settings->Portal. The variables to create are:
    DattoRMMId
#>

##### Required Variables #####

$Client =  $SecureVars.DattoRMMId

##### Script Logic #####

if(($Client -eq $null)) {
    Write-Output "ERROR: The secure variables DattoRMMId is not provided"
}

else {    
    $InstallerName = "AgentSetup.exe"
    $InstallerPath = Join-Path $Env:TMP $InstallerName
    $DownloadURL = "https://concord.centrastage.net/csm/profile/downloadAgent/" + $Client

    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($DownloadURL, $InstallerPath)
    Start-Process $InstallerPath -wait -PassThru
} 