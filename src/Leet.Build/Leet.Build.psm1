#requires -version 6

Set-StrictMode -Version 2

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'Continue'

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Remove-ImportedModules
}

<#
.SYNOPSIS
Execute the given Leet.Build command.

.PARAMETER RepositoryRoot
The path to the repository root folder.

.PARAMETER Arguments
Command arguments to be passed to the command.
#>
function Invoke-LeetBuildCommand ( [String]   $RepositoryRoot ,
                                   [String[]] $Arguments      ) {
    Write-Invocation $MyInvocation
    Import-ProjectExtensionModule $RepositoryRoot
    $commandName = Set-CommandArguments $RepositoryRoot $Arguments
    Invoke-Command $commandName -IncludeExtensions -ThrowOnNoHandler
}

<#
.SYNOPSIS
Imports Leet.Build.Project extension module from the specified repository.

.PARAMETER RepositoryRoot
The directory to the project's root directory path.
#>
function Import-ProjectExtensionModule ( [String] $RepositoryRoot ) {
    $projectExtensionModule = Join-Paths $RepositoryRoot ('build', 'Leet.Build.Project.psd1')
    if (Test-Path $projectExtensionModule -PathType Leaf) {
        Import-Module $projectExtensionModule -Force -Global
    }
}

<#
.SYNOPSIS
Default handler for verify command 
#>
function Invoke-OnLeetBuildVerifyCommand {
    Invoke-Command 'build' -IncludeExtensions
    Invoke-Command 'test' -IncludeExtensions
}

<#
.SYNOPSIS
Removed all imported Leet.Build modules.
#>
function Remove-ImportedModules {
    Remove-Module Leet.Build.* -Force
}

Export-ModuleMember -Variable '*' -Alias '*' -Function '*' -Cmdlet '*'
