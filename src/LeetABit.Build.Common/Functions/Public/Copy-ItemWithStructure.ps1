#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Diagnostics.CodeAnalysis

Set-StrictMode -Version 3.0

function Copy-ItemWithStructure {
    <#
    .SYNOPSIS
        Copies specified item to a destination directory with the base subdirectory structure.
    .DESCRIPTION
        Copy-ItemWithStructure cmdlet copies specified item to the destination location. Copied items are being stored inside a subdirectory structure that reflects structure between source files and source base directory.
    .PARAMETER Path
        Path to normalize.
    .PARAMETER LiteralPath
        Path to normalize.
    .PARAMETER Base
        Path to the base source directory from which the subdirectory evaluation shall begin.
    .PARAMETER Destination
        Path to the destination folder to which the files shall be copied.
    .EXAMPLE
        PS> Copy-ItemWithStructure -SourceBaseDirectory "C:\BaseDirectory" -SourceFiles "Subdirectory\File.txt" -DestinationDirectory "C:\DestinationDirectory"

        Copies source File.txt item to the C:\DestinationDirectory\Subdirectory location.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = 'Medium',
                   DefaultParameterSetName = 'Path')]

    [SuppressMessageAttribute(
        'PSReviewUnusedParameter',
        'Destination',
        Justification = 'False positive as rule does not scan child scopes: https://github.com/PowerShell/PSScriptAnalyzer/issues/1472')]
    param (
        [Parameter(HelpMessage = 'Provide a path to an item to copy.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'Path')]
        [String[]]
        $Path,

        [Parameter(HelpMessage = 'Provide a path to an item to copy.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'LiteralPath')]
        [String[]]
        $LiteralPath,

        [Parameter(HelpMessage = 'Provide path to the base source directory from which the subdirectory evaluation shall begin.',
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [ValidateContainerPathAttribute()]
        [String]
        $Base,

        [Parameter(HelpMessage = 'Provide path to the destination directory to which the files with directory structure shall be copied.',
                   Position = 2,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [ValidateNonLeafPathAttribute()]
        [String]
        $Destination)

    begin {
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $SelectedPath = if ($PSCmdlet.ParameterSetName -eq 'Path') { $Path } else { $LiteralPath }
        $parameters = @{ "$($PSCmdlet.ParameterSetName)" = $SelectedPath }
    }

    process {
        Resolve-RelativePath @parameters -Base $Base | ForEach-Object {
            $sourcePath = Join-Path $Base $_
            $destinationPath = Join-Path $Destination $_

            if (Test-Path $destinationPath) {
                Remove-Item $destinationPath -Force -Recurse
            }

            $destinationDirectory = Split-Path $destinationPath -Parent
            if (-not (Test-Path $destinationDirectory -PathType Container)) {
                if (Test-Path $destinationDirectory -PathType Leaf) {
                    if ($PSCmdlet.ShouldProcess($LocalizedData.Copy_ItemWithStructure_File_FilePath -f $destinationDirectory,
                                                $LocalizedData.Copy_ItemWithStructure_Remove)) {
                        Remove-Item $destinationDirectory -Recurse -Force
                    }
                }

                if ($PSCmdlet.ShouldProcess($LocalizedData.Copy_ItemWithStructure_Directory_DirectoryPath -f $destinationDirectory,
                                            $LocalizedData.Copy_ItemWithStructure_Create)) {
                    [void](New-Item -Path $destinationDirectory -ItemType Directory -Force)
                }
            }

            if ($PSCmdlet.ShouldProcess($LocalizedData.Copy_ItemWithStructure_File_FilePath -f $destinationPath,
                                        $LocalizedData.Copy_ItemWithStructure_CopyWithReplace)) {
                Copy-Item -Path $sourcePath -Destination $destinationPath -Force -Recurse
            }
        }
    }
}
