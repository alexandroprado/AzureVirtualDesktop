# 7Zip Download
# https://www.7-zip.org/download.html
# MSIX Packaging Tool Download
# https://docs.microsoft.com/en-us/windows/msix/packaging-tool/tool-overview
# Time stamp URL
# http://timestamp.verisign.com/scripts/timstamp.dll

# Add the package to the OS
Add-AppxPackage '<MSIX Package>'

# Get the appx
Get-AppxPackage | where-object { $_.name -like "*<Package Name>*" }

# Remove with the PackageFullName
Remove-AppxPackage -Package <FullPackageName>
