# Connect to Azure 
Connect-AzAccount
# Or verify the connection
Get-AzContext


# Set the variables to create the storage account
$resourceGroupName = "<ResourceGroup>"
$region = "<Region>"
# Storage Account Name must be globally unique
# Must be lowercase
$storageAccountName = "<StorageAccountName>"
# Test the storage account name availability
Get-AzStorageAccountNameAvailability -Name $storageAccountName

# Run this command to create the Resource Group
# Skip if the Resource Group already exists
New-AzResourceGroup -Name $resourceGroupName -Location $region

# Add one of the two storage account types below
# Standard LRS is okay for testing, but premium is recommended for production
$storAcct = New-AzStorageAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $storageAccountName `
    -SkuName Standard_LRS `
    -Location $region `
    -Kind StorageV2 `
    -EnableLargeFileShare
# Premium Storage - Use this for production
$storAcct = New-AzStorageAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $storageAccountName `
    -SkuName Premium_LRS `
    -Location $region `
    -Kind FileStorage


# Download and unzip the AzFilesHybrid Module
# https://github.com/Azure-Samples/azure-files-samples/releases
# Set the execution policy and
# Go to extracted folder and run CopyToPSPath.ps1
# Next, import the module
Set-ExecutionPolicy -ExecutionPolicy Unrestricted
.\CopyToPsPath.ps1
Import-Module azfileshybrid

# Join the storage account to Windows AD
Join-AzStorageAccountForAuth `
    -ResourceGroupName $ResourceGroupName `
    -StorageAccountName $StorageAccountName `
    -DomainAccountType "<ComputerAccount|ServiceLogonAccount>" `
    -OrganizationalUnitDistinguishedName "<ou-distinguishedname-here>" # If you don't provide the OU name as an input parameter, the AD identity that represents the storage account is created under the root directory.

<# Public Version
Join-AzStorageAccountForAuth `
        -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName `
        -DomainAccountType "<ComputerAccount|ServiceLogonAccount>" `
        -OrganizationalUnitDistinguishedName "<ou-distinguishedname-here>" # If you don't provide the OU name as an input parameter, the AD identity that represents the storage account is created under the root directory.
#>

#You can run the Debug-AzStorageAccountAuth cmdlet to conduct a set of basic checks on your AD configuration with the logged on AD user. This cmdlet is supported on AzFilesHybrid v0.1.2+ version. For more details on the checks performed in this cmdlet, see Azure Files Windows troubleshooting guide.
Debug-AzStorageAccountAuth -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Verbose

# Confirm the feature is enabled
# Get the target storage account
$storageAccount = Get-AzStorageAccount `
    -ResourceGroupName $ResourceGroupName `
    -Name $StorageAccountName
# List the directory service of the selected service account
$storageAccount.AzureFilesIdentityBasedAuth.DirectoryServiceOptions
# List the directory domain information if the storage account has enabled AD DS authentication for file shares
$storageAccount.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties


# Create the file share
$ShareName = '<ShareName>'
# Set the AccessTier, Options are TransactionOptimized, Hot, Cold or Premium
New-AzRmStorageShare `
    -ResourceGroupName $ResourceGroupName `
    -StorageAccountName $StorageAccountName `
    -Name $ShareName `
    -AccessTier Premium `
    -QuotaGiB 1024


# Set Share (RBAC) permissions
# Connect to Azure AD with an Azure AD Global Admin (May be differnt from a Subscription Admin )
Connect-AzureAD 
#Assign Share Level Permissions with Azure AD Roles
#Constrain the scope to the target file share
$SubscriptionId = (Get-AzContext).Subscription.Id
$scope = "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Storage/storageAccounts/$StorageAccountName/fileServices/default/fileshares/$ShareName"

#Start with the Share Admin Account
$FileShareContributorRole = Get-AzRoleDefinition "Storage File Data SMB Share Elevated Contributor" #Use one of the built-in roles: Storage File Data SMB Share Reader, Storage File Data SMB Share Contributor, Storage File Data SMB Share Elevated Contributor
# Verify the UPN
$user = Get-AzureADUser -SearchString "<StorageAdminAccount>"
#Assign the custom role to the target identity with the specified scope.
New-AzRoleAssignment -SignInName $user.UserPrincipalName -RoleDefinitionName $FileShareContributorRole.Name -Scope $scope

#Give Read Access to the WVD User and Session Host Group
# Add the Group names for Read access
$Groups = "<UserGroupe>", "<ComputerGroup>"
#Set the SMB Role
$FileShareContributorRole = Get-AzRoleDefinition "Storage File Data SMB Share Reader" #Use one of the built-in roles: Storage File Data SMB Share Reader, Storage File Data SMB Share Contributor, Storage File Data SMB Share Elevated Contributor
#Assign the custom role to the target identity with the specified scope.
foreach ($group in $groups) {
    $GroupID = (Get-AzureADGroup -SearchString $group).ObjectId
    New-AzRoleAssignment -ObjectId $GroupID -RoleDefinitionName $FileShareContributorRole.Name -Scope $scope
}


# Mount the file share as supper user
$StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).Value[0]
#  Run the code below to test the connection and mount the share
$connectTestResult = Test-NetConnection -ComputerName "$StorageAccountName.file.core.windows.net" -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    net use T: "\\$StorageAccountName.file.core.windows.net\$ShareName" /user:Azure\$StorageAccountName $StorageAccountKey
} 
else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN,   Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

# Disconnect the Storage Account
net use T: /delete