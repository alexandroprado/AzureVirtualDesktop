# Set Personal Host Pool Assignment Type

# Connect to Azure AD
Connect-AzAccount

# Get current connection status
Get-AzContext

# Set host pool variables
$resourceGroup = "AzureVirtualDesktop"
$hostPool = "pooled"
$sessionHost = "AVD-0"
$userUpn = "avduser1@adamtechnology.co.uk"

# Get the Host Pool settings
Get-AzWvdHostPool -ResourceGroupName $resourceGroup -Name $hostPool | Format-List

# Change Host Pool Assignment Type
Update-AzWvdHostPool -ResourceGroupName $resourceGroup -Name $hostPool -PersonalDesktopAssignmentType  Direct

# View Session Host Assignemtn
Get-AzWvdSessionHost -ResourceGroupName $resourceGroup -HostPoolName $hostPool -Name $sessionHost | Format-List

Update-AzWvdSessionHost -ResourceGroupName $resourceGroup -HostPoolName $hostPool -Name $sessionHost -AssignedUser $userUpn