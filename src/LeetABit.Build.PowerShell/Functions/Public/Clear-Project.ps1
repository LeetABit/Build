#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Clear-Project {
    <#
    .SYNOPSIS
        Cleans artifacts produced for the specified project.
    .PARAMETER LiteralPath
        Path to the project which artifacts have to be cleaned.
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
        $RelativeProjectPath = Resolve-RelativePath -Path $LiteralPath -Base $SourceRoot
        $artifactPath = Join-Path $ArtifactsRoot $RelativeProjectPath

        if (Test-Path $LiteralPath -PathType Leaf) {
            $itemPath = Get-Item $LiteralPath
            $path = Join-Path $itemPath.DirectoryName "$($itemPath.BaseName).*.nupkg"
            if (Test-Path $path) {
                Remove-Item $path -Force
            }
        }

        if (Test-Path $artifactPath) {
            Remove-Item $artifactPath -Recurse -Force
        }

        if ((Test-Path $ArtifactsRoot) -and -not (Get-ChildItem $ArtifactsRoot -File -Recurse)) {
            Remove-Item $ArtifactsRoot -Force -Recurse
        }
    }
}
