#description: Reboots the Azure VM
#execution mode: Individual
#tags: Axon, Azure, Reboot, Restart

<#
Notes:
This script reboots the Azure VM

#>

##### Required Variables #####

##### Script Logic #####

$sub = get-azsubscription -SubscriptionId $AzureSubscriptionId

set-azcontext -subscription $sub 

Restart-AzVM -ResourceGroupName $AzureResourceGroupName -Name $AzureVMName