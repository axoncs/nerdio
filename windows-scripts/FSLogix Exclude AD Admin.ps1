#description: Excludes the admin user from FSLogix profiles
#execution mode: Individual
#tags: Axon, AVD, Exclude

<#
Notes:
The installation script requires an account key and an organization key, 
which are used to associate the agent with a specific organization 
within the Huntress partner account. 
You must provide secure variables to this script as seen in the Required Variables section. 
Set these up in Nerdio Manager under Settings->Integrations->Directory. The variables to create are:
    ADUsername
#>

##### Required Variables #####

$admin =  $ADUsername

##### Script Logic #####

if(($admin -eq $null)) {
    Write-Output "ERROR: The secure variables ADUsername is not being passed"
}

else {    
Add-LocalGroupMember -Group "FSLogix ODFC Exclude List" -Member $admin
Add-LocalGroupMember -Group "FSLogix Profile Exclude List" -Member $admin
} 


