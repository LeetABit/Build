#requires -version 6

Set-StrictMode -Version 2

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'Continue'

$extensionModules = @{}

<#
.SYNOPSIS
Imports all Leet.Build project extension modules from the specified repository root directory.

.PARAMETER RepositoryRoot
The directory to the project's root directory path.
#>
function Import-ProjectExtensionModules ( [String] $RepositoryRoot ) {
    $extensionRoot = Join-Path $RepositoryRoot 'build'
    Get-ChildItem $extensionRoot -Filter '*.psd1' | ForEach-Object {
        if (Test-Path $_.FullName -PathType 'Leaf') {
            $script:extensionModules[$_.FullName] = Leet.Build.Modules\Import-ModuleFromManifest $_.FullName
        }
    }
}

<#
.SYNOPSIS
Removes all Leet.Build project's extension modules imprted.
#>
function Remove-ProjectExtensionModules () {
    foreach ($extensionModule in $script:extensionModules.Keys) {
        Leet.Build.Modules\Remove-ModuleFromManifest $extensionModule
    }

    $script:extensionModules = @{}
}

<#
.SYNOPSIS
Gets all project's extension modules imported from the project's root directory.
#>
function Get-ExtensionModules () {
    return $script:extensionModules.Values
}

Export-ModuleMember -Variable '*' -Alias '*' -Function '*' -Cmdlet '*'
