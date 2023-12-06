#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Build-Project {
    <#
    .SYNOPSIS
        Build specified PowerShell project.
    .PARAMETER LiteralPath
        Path to the project which artifacts have to be built.
    .PARAMETER SourceRoot
        Path to the source root directory.
    .PARAMETER ArtifactsRoot
        Path to the artifacts root directory.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param(
        [Parameter(HelpMessage = 'Provide path for the project which artifacts have to be cleaned.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $LiteralPath,

        [Parameter(HelpMessage = 'Provide path for the source root directory.',
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $SourceRoot,

        [Parameter(HelpMessage = 'Provide path for the artifacts root directory.',
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $ArtifactsRoot
    )

    process {
        LeetABit.Build.Common\Copy-ItemWithStructure -Path $LiteralPath -Base $SourceRoot -Destination $ArtifactsRoot
    }
}
