#description: Install Windows Defender.
#execution mode: Individual
#tags: Axon, Windows, Defender
# Some organizations, use non-persistent virtual machines for their users
# A non-persistent machine is created from a master image
# Every new machine instance has a different name and these machines are available via pool
# Every user logon \ reboot returns machine to image state loosing all user data
# This script provides a solution for onboarding such machines
# We would like to have sense unique id per machine name in organization
# For that purpose, senseGuid is set prior to onboarding
# The guid is created deterministically based on combination of orgId and machine name 
# This script is intended to be integrated in golden image startup
Param (	
<#
Notes:

Set these up in Nerdio Manager under Settings->Portal. The variables to create are:

		
#>

##### Required Variables #####
$onboardingPackageLocation = "C:\Axon\WindowsDefender"


##### Script Logic #####


	[string]
	[ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_ -PathType ‘Container’})]
)

Add-Type @'
using System; 
using System.Diagnostics; 
using System.Diagnostics.Tracing; 
namespace Sense 
{ 
	[EventData(Name = "Onboard")]
	public struct Onboard
	{
		public string Message { get; set; }
	} 
	public class Trace 
	{
		public static EventSourceOptions TelemetryCriticalOption = new EventSourceOptions(){Level = EventLevel.Informational, Keywords = (EventKeywords)0x0000800000000000, Tags = (EventTags)0x0200000}; 
		public void WriteMessage(string message)
		{
			es.Write("OnboardNonPersistentMachine", TelemetryCriticalOption, new Onboard {Message = message});
		} 
		private static readonly string[] telemetryTraits = { "ETW_GROUP", "{5ECB0BAC-B930-47F5-A8A4-E8253529EDB7}" }; 
		private EventSource es = new EventSource("Microsoft.Windows.Sense.Client.VDI",EventSourceSettings.EtwSelfDescribingEventFormat,telemetryTraits);
	}
}
'@

$logger = New-Object -TypeName Sense.Trace;

function Trace([string] $message)
{
    $logger.WriteMessage($message)
}

function CreateGuidFromString([string]$str)
{
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($str)
    $sha1CryptoServiceProvider = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
    $hashedBytes = $sha1CryptoServiceProvider.ComputeHash($bytes)
    [System.Array]::Resize([ref]$hashedBytes, 16);
    return New-Object System.Guid -ArgumentList @(,$hashedBytes)
}

function GetComputerName 
{
    return [system.environment]::MachineName
}

function ReadOrgIdFromOnboardingScript($onboardingScript)
{
    return select-string -path $onboardingScript -pattern "orgId\\\\\\`":\\\\\\`"([^\\]+)" | %{ $_.Matches[0].Groups[1].Value }
}

function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    return (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

if ((Test-Administrator) -eq $false)
{
    Write-Host -ForegroundColor Red "The script should be executed with admin previliges"
    Trace("Script wasn't executed as admin");
    Exit 1;
}

Write-Host "Locating onboarding script under:" $onboardingPackageLocation

$onboardingScript = [System.IO.Path]::Combine($onboardingPackageLocation, "WindowsDefenderATPOnboardingScript.cmd");

if(!(Test-Path -path $onboardingPackageLocation)){write-host 'creating path' ; New-Item -Path "c:\Axon" -Name "Axon\WindowsDefender" -ItemType "directory" -force}
IF([Net.SecurityProtocolType]::Tls12) {[Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12}
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/axoncs/nerdio/main/windows-scripts/WindowsDefenderATPOnboardingScript.cmd" -OutFile $onboardingScript

$onboardingScript = [System.IO.Path]::Combine($onboardingPackageLocation, "WindowsDefenderATPOnboardingScript.cmd");

if(![System.IO.File]::Exists($onboardingScript))
{
    Write-Host -ForegroundColor Red "Onboarding script not found:" $onboardingScript
    Trace("Default Onboarding script not found")
    $onboardingScript = [System.IO.Path]::Combine($onboardingPackageLocation, "DeviceComplianceOnboardingScript.cmd");
    if(![System.IO.File]::Exists($onboardingScript)) 
    {
        Write-Host -ForegroundColor Red "Onboarding script not found:" $onboardingScript
        Trace("Compliance Onboarding script not found")
        Exit 2;
    }
}

$orgId = ReadOrgIdFromOnboardingScript($onboardingScript);
if ([string]::IsNullOrEmpty($orgId))
{
    Write-Host -ForegroundColor Red "Could not deduct organization id from onboarding script:" $onboardingScript
    Trace("Could not deduct organization id from onboarding script")
    Exit 3;
}
Write-Host "Identified organization id:" $orgId

$computerName = GetComputerName;
Write-Host "Identified computer name:" $computerName

$id = $orgId + "_" + $computerName;
$senseGuid = CreateGuidFromString($id);
Write-Host "Generated senseGuid:" $senseGuid


$senseGuidRegPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Advanced Threat Protection"
$senseGuidValueName = "senseGuid";
$populatedSenseGuid = [Microsoft.Win32.Registry]::GetValue($senseGuidRegPath, $senseGuidValueName, $null)
if ($populatedSenseGuid)
{
    Write-Host -ForegroundColor Red "SenseGuid already populated:" $populatedSenseGuid
    Trace("SenseGuid already populated")
    Exit 4;
}
[Microsoft.Win32.Registry]::SetValue($senseGuidRegPath, $senseGuidValueName, $senseGuid)
Write-Host "SenseGuid was set:" $senseGuid


[Microsoft.Win32.Registry]::SetValue($vdiTagRegPath, $vdiTagValueName, $vdiTag)
Write-Host "VDI tag was set:" $vdiTag

Write-Host "Starting onboarding"
&$onboardingScript
if ($LASTEXITCODE -ne 0)
{
    Write-Host -ForegroundColor Red "Failed to onboard sense service from: $($onboardingScript). Exit code: $($LASTEXITCODE). To troubleshoot, please read https://technet.microsoft.com/en-us/itpro/windows/keep-secure/troubleshoot-onboarding-windows-defender-advanced-threat-protection"
    Trace("Failed to onboard sense service. LASTEXITCODE=" + $LASTEXITCODE)
    Exit 5;
}

Write-Host -ForegroundColor Green "Onboarding completed successfully"
Trace("SUCCESS")