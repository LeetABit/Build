#requires -version 6

Set-StrictMode -Version 2

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'Continue'

<#
.SYNOPSIS
Imports all Leet.Build modules from the specified directory.

.PARAMETER RepositoryRoot
The directory to the path from which all Leet.build modules shall be imported.
#>
function Import-ProjectExtensionModules ( [String] $ProjectRoot ) {
    $extensionRoot = Join-Path $ProjectRoot 'build'
    Get-ChildItem $extensionRoot -Filter '*.psd1' | ForEach-Object {
        if (Test-Path $_.FullName -PathType 'Leaf') {
            Leet.Build.Modules\Import-ModuleFromManifest $_.FullName
        }
    }
}

Export-ModuleMember -Variable '*' -Alias '*' -Function '*' -Cmdlet '*'
