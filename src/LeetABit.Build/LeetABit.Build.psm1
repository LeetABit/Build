#requires -version 6
using namespace System.Collections
using namespace System.Collections.Generic
using module LeetABit.Build.Common
using module LeetABit.Build.Extensibility

Set-StrictMode -Version 3.0
Import-LocalizedData -BindingVariable LocalizedData -FileName LeetABit.Build.Resources.psd1

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Remove-Module LeetABit.Build.* -Force
}


##################################################################################################################
# Public Commands
##################################################################################################################


function Build-Repository {
    <#
    .SYNOPSIS
    Performs a build operation on all projects located in the specified repository.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # The path to the repository root folder.
        [Parameter(HelpMessage = "Provide path to the repository's root directory.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [ValidateContainerPathAttribute()]
        [String]
        $RepositoryRoot,

        # Name of the build task to invoke.
        [Parameter(Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [ValidateIdentifierOrEmptyAttribute()]
        [AllowEmptyString()]
        [String]
        $TaskName,

        # Dictionary of buildstrapper arguments (including dynamic ones) that have been successfully bound.
        [Parameter(Position = 2,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [IDictionary]
        $NamedArguments,

        # Arguments to be passed to the target.
        [Parameter(Position = 3,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $UnknownArguments)

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        LeetABit.Build.Logging\Write-Invocation -Invocation $MyInvocation
        LeetABit.Build.Arguments\Set-CommandArgumentSet -RepositoryRoot $RepositoryRoot -NamedArguments $NamedArguments -UnknownArguments $UnknownArguments
        Initialize-WellKnownParameters -RepositoryRoot $RepositoryRoot
        Import-RepositoryExtension -RepositoryRoot $RepositoryRoot

        $TaskName = LeetABit.Build.Arguments\Find-CommandArgument -ParameterName TaskName -DefaultValue $TaskName
        $projectPath = LeetABit.Build.Arguments\Find-CommandArgument -ParameterName SourceRoot

        LeetABit.Build.Extensibility\Resolve-Project $projectPath 'LeetABit.Build.Repository' $TaskName | ForEach-Object {
            $projectPath, $extensionName = $_
            LeetABit.Build.Extensibility\Invoke-BuildTask $extensionName $TaskName $projectPath
        }
    }
}


##################################################################################################################
# Private Commands
##################################################################################################################


function Initialize-WellKnownParameters {
    <#
    .SYNOPSIS
    Initializes a set of well known parameters with its default values.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # The directory to the repository's root directory path.
        [Parameter(HelpMessage = "Provide path to the repository's root directory.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $RepositoryRoot)

    process {
        LeetABit.Build.Arguments\Set-CommandArgument 'ArtifactsRoot' (Join-Path $RepositoryRoot 'artifacts') -ErrorAction SilentlyContinue
        LeetABit.Build.Arguments\Set-CommandArgument 'SourceRoot' (Join-Path $RepositoryRoot 'src') -ErrorAction SilentlyContinue
        LeetABit.Build.Arguments\Set-CommandArgument 'TestRoot' (Join-Path $RepositoryRoot 'test') -ErrorAction SilentlyContinue
    }
}


function Import-RepositoryExtension {
    <#
    .SYNOPSIS
    Executes LeetABit.Build.Repository scripts from the specified repository.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # The directory to the repository's root directory path.
        [Parameter(HelpMessage = "Provide path to the repository's root directory.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $RepositoryRoot)

    process {
        Get-ChildItem -Path $RepositoryRoot -Filter "LeetABit.Build.Repository.ps1" -Recurse | ForEach-Object {
            . "$_"
        }
    }
}


Export-ModuleMember -Function '*' -Variable '*' -Alias '*' -Cmdlet '*'
