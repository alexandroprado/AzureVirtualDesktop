# Log in to Azure with:
Connect-AzAccount

# Verify your logged in with
Get-AzContext

# Create the Resource Group
New-AzResourceGroup -Name '<ResourceGroupName>' -Location '<Location>'

# Create a Shared Image Gallery
New-AzGallery -GalleryName '<GalleryName>' -ResourceGroupName '<ResourceGroupName>' -Location '<Location>'

# View existing Shared Image Gallery
Get-AzGallery -ResourceGroupName AzureVirtualDesktop -Name AVDImageGallery