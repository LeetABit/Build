#requires -version 6

Set-StrictMode -Version 2

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'Continue'

$BackupPSModulePath = $env:PSModulePath
$ImportedModulesFromDirectories  = @{}
$ImportedModulesFromManifests  = @{}

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Undo-ModuleChanges
}

<#
.SYNOPSIS
Imports all Leet.Build modules from the specified directory.

.PARAMETER DirctoryPath
The directory to the path from which all Leet.build modules shall be imported.
#>
function Import-ModulesFromDirectory ( [String] $DirctoryPath ) {
    $localBackupPSModulePath = $env:PSModulePath
    try {
        Write-Verbose "Temporarily setting `$env:PSModulePath to '$DirctoryPath'."
        $env:PSModulePath = $DirctoryPath
        $availableModules = Get-Module 'Leet.Build*' -ListAvailable
        Write-Verbose "Adding '$DirctoryPath' to `$env:PSModulePath."
        $env:PSModulePath = Set-DirectoryAsPathHead $DirctoryPath $localBackupPSModulePath
        $script:ImportedModulesFromDirectories[$DirctoryPath] = @()

        foreach ($availableModule in $availableModules) {
            if ($availableModule.Name -eq 'Leet.Build.Modules') {
                continue
            }

            Write-Host "Importing '$($availableModule.Name)' module..."
            $importedModule = Import-Module -Name $($availableModule.Name) -RequiredVersion $($availableModule.Version) -Global -PassThru
            $script:ImportedModulesFromDirectories[$DirctoryPath] += $importedModule
        }
    } catch {
        $env:PSModulePath = $localBackupPSModulePath
        throw
    }
}

<#
.SYNOPSIS
Unloads Leet.Build modules imported from the specified directory location.

.PARAMETER DirectoryPath
The path to the directory modules from which shall be unloaded.
#>
function Remove-ModulesFromDirectory ( [String] $DirctoryPath ) {
    if ($script:ImportedModulesFromDirectories.ContainsKey($DirctoryPath)) {
        $script:ImportedModulesFromDirectories[$DirctoryPath] | Foreach-Object {
            Write-Host "Removing '$($_.Name)' module..."
            Remove-Module $_ -ErrorAction Continue -Force
        }

        $script:ImportedModulesFromDirectories.Remove($DirctoryPath)
        Write-Verbose "Removing first occurrence of '$DirctoryPath' from `$env:PSModulePath."
        $env:PSModulePath = Remove-FirstDirectoryFromPath $DirectoryPath $env:PSModulePath
    }
}

<#
.SYNOPSIS
Imports a specified module manifest.

.PARAMETER ManifestPath
The path to the module manifest file to import.
#>
function Import-ModuleFromManifest ( [String] $ManifestPath ) {
    $moduleName = $(Test-ModuleManifest $ManifestPath).Name
    Write-Host "Importing '$moduleName' module..."
    $script:ImportedModulesFromManifests[$ManifestPath] = Import-Module -Name $ManifestPath -Global -PassThru
}

<#
.SYNOPSIS
Unloads a module represented by the specified manifest.

.PARAMETER ManifestPath
The path to the module manifest to unload.
#>
function Remove-ModuleFromManifest ( [String] $ManifestPath ) {
    if ($script:ImportedModulesFromManifests.ContainsKey($ManifestPath)) {
        $moduleName = $(Test-ModuleManifest $ManifestPath).Name
        Write-Host "Removing '$moduleName' module..."
        Remove-Module $script:ImportedModulesFromManifests[$ManifestPath] -ErrorAction Continue -Force
        $script:ImportedModulesFromManifests.Remove($ManifestPath)
    }
}

<#
.SYNOPSIS
Adds a specified directory to the $Path variable head.

.PARAMETER Directory
A directory to be added to the $Path.

.PARAMETER Path
A value of the path set to which the directory shall be added.
#>
function Set-DirectoryAsPathHead ( [String] $Directory ,
                                   [String] $Path      ) {
    $delimiter = if ($IsWindows) { ';' } else { ':' }
    return "$Directory$delimiter$Path"
}

<#
.SYNOPSIS
Removes a first occurrence of the specified directory from the $Path veraible.

.PARAMETER Directory
The directory to remove from $Path variable.

.PARAMETER Path
A value of the path set from which the directory shall be removed.

.NOTES
Equality for $Directory and each item in the $Path parameter is determined using [System.IO.Path]::GetFullPath method.
#>
function Remove-FirstDirectoryFromPath ( [String] $Directory ,
                                         [String] $Path      ) {
    $delimiter = if ($IsWindows) { ';' } else { ':' }
    $resolvedDirectory = [System.IO.Path]::GetFullPath($Directory)
    $result = ""

    foreach ($item in $Path -split $delimiter) {
        $resolvedItem = [System.IO.Path]::GetFullPath($item)
        if ($resolvedDirectory -ne $resolvedItem) {
            if ($result) {
                $result += ";$item"
            } else {
                $result = $item
            }
        }
    }
    
    return $result
}

<#
.SYNOPSIS
Undo all session state changes introduced by this module.
#>
function Undo-ModuleChanges () {
    Write-Verbose "Undoing changes for `$env:PSModulePath."
    $env:PSModulePath = $script:BackupPSModulePath
    while ($script:ImportedModulesFromDirectories.Count -gt 0) {
        $directoryPath = $script:ImportedModulesFromDirectories.Keys | Select-Object -Last 1
        Remove-ModulesFromDirectory $directoryPath
    }

    while ($script:ImportedModulesFromManifests.Count -gt 0) {
        $directoryPath = $script:ImportedModulesFromManifests.Keys | Select-Object -Last 1
        Remove-ModuleFromManifest  $directoryPath
    }
}

Export-ModuleMember -Variable '*' -Alias '*' -Function '*' -Cmdlet '*'
