#requires -version 6
using namespace Microsoft.PowerShell.Commands

Set-StrictMode -Version 3.0

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
        $RepositoryRoot,

        # Collection fo extension modules to import.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [ModuleSpecification[]]
        $ExtensionModule)

    process {
        LeetABit.Build.Arguments\Add-CommandArgument 'ArtifactsRoot' (Join-Path $RepositoryRoot 'artifacts') -ErrorAction SilentlyContinue
        LeetABit.Build.Arguments\Add-CommandArgument 'SourceRoot' (Join-Path $RepositoryRoot 'src') -ErrorAction SilentlyContinue
        LeetABit.Build.Arguments\Add-CommandArgument 'TestRoot' (Join-Path $RepositoryRoot 'test') -ErrorAction SilentlyContinue
        LeetABit.Build.Arguments\Add-CommandArgument 'ReferenceDocsRoot' (Join-Path -Path $RepositoryRoot -ChildPath 'docs' -AdditionalChildPath 'Reference') -ErrorAction SilentlyContinue
        [ModuleSpecification[]]$existingExtensionModule = LeetABit.Build.Arguments\Find-CommandArgument -ParameterName 'ExtensionModule'
        [ModuleSpecification[]]$uniqueExtensionModule = (($existingExtensionModule + $ExtensionModule) | Select-Object -Unique)
        LeetABit.Build.Arguments\Add-CommandArgument 'ExtensionModule' $uniqueExtensionModule -ErrorAction SilentlyContinue
    }
}
