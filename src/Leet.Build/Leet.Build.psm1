#requires -version 6

Set-StrictMode -Version 2

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'Continue'

<#
.SYNOPSIS
Execute the given Leet.Build command.

.PARAMETER RepositoryRoot
The path to the repository root folder.

.PARAMETER Arguments
Command arguments to be passed to the command.

.EXAMPLE
Invoke-LeetBuildCommand "msbuild" /t:Rebuild
#>
function Invoke-LeetBuild ( [String]   $RepositoryRoot ,
                            [String[]] $Arguments      ) {
    Write-Invocation $MyInvocation
    Write-Step -Message "Starting Leet.Build" -Major
    Leet.Build.Commands\Invoke-Command $RepositoryRoot $Arguments
    Write-Success
}

Export-ModuleMember -Variable '*' -Alias '*' -Function '*' -Cmdlet '*'
