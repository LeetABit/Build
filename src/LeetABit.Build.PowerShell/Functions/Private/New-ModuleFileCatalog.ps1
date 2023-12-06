#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function New-ModuleFileCatalog {
    <#
    .SYNOPSIS
    Sets an Authenticode Signature for all powershell artifacts.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = "Low")]
    [OutputType([System.IO.FileInfo])]

    param (
        # Path to the module manifest file.
        [Parameter(HelpMessage = 'Provide path to the module manifest file.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [System.IO.FileInfo]
        $ModuleFile)

    process {
        $directoryPath = $ModuleFile.Directory.FullName
        $catalogFile = Join-Path $directoryPath "$($ModuleFile.BaseName).cat"
        if ($PSCmdlet.ShouldProcess($LocalizedData.Resource_FileCatalog,
                                    $LocalizedData.Operation_New)) {
            New-FileCatalog -CatalogFilePath $catalogFile -CatalogVersion 2.0 -Path $directoryPath
        }
    }
}
