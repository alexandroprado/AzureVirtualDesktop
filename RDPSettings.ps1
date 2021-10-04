# View the current RDP Settings
Get-AzWvdHostPool -ResourceGroupName AzureVirtualDesktop -Name Pooled | Format-list Name, CustomRdpProperty

# Remove existing settings
Update-AzWvdHostPool -ResourceGroupName AzureVirtualDesktop -Name Pooled -CustomRdpProperty ""  

# Add an RDP Property
Update-AzWvdHostPool -ResourceGroupName AzureVirtualDesktop -Name Pooled -CustomRdpProperty redirectclipboard:i:0
Update-AzWvdHostPool -ResourceGroupName AzureVirtualDesktop -Name Pooled -CustomRdpProperty redirectprinters:i:0

# Add multiple RDP Properties
$properties = “redirectclipboard:i:0;redirectprinters:i:0;drivestoredirect:s:”
Update-AzWvdHostPool -ResourceGroupName AzureVirtualDesktop -Name Pooled -CustomRdpProperty $properties