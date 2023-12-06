#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Get-PowerShellProjectsPattern {
    <#
    .SYNOPSIS
        Gets a path pattern to all artifacts produced by PowerShell projects.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String])]

    param (
        # Specified whether only signable files shall be obtained.
        [Parameter(Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [Switch]
        $SignableOnly)

    process {
        $extensions = ('^.*(?<!Resources)\.psd1', '^.+\.ps1$')

        if (-not $SignableOnly) {
            $extensions += ('^.+\.sh$', '^.+\.cmd$')
        }

        $extensions
    }
}
