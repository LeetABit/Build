#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Management.Automation

Set-StrictMode -Version 3.0

function Read-ModuleMetadata {
    <#
    .SYNOPSIS
        Initializes most common properties of the LeetABit.Build module.
    .PARAMETER Obj
        Object to convert.
    .PARAMETER UnregisterOnRemove
        Determines whether the module should unregister build extension on remove.
    #>
    [CmdletBinding()]
    [OutputType([ModuleMetadataInfo[]])]

    param (
        [Parameter(HelpMessage = "Provide the module's invocation info object.",
                   Mandatory = $True)]
        [InvocationInfo[]]
        $Invocation
    )

    process {
        $module = $Invocation.MyCommand.ScriptBlock.Module
        $moduleBase = $module.ModuleBase
        $moduleName = $module.Name
        $resourcesFileName = "$moduleName.Resources.psd1"
        $resourcesFilePath = Join-Path $moduleBase $resourcesFileName

        if (Test-Path $resourcesFilePath -PathType Leaf) {
            $resourcesFile = Get-Item $resourcesFilePath
        }

        $scriptFiles = Get-ChildItem -Path $moduleBase -Filter '*.ps1' -Recurse

        $functionsBase = Join-Path $moduleBase 'Functions'
        $publicFunctionsBase = Join-Path $functionsBase 'Public'
        $publicFunctionNames = if (Test-Path $publicFunctionsBase -PathType Container) {
            $items = Get-ChildItem "$publicFunctionsBase\*.ps1"
            $items.BaseName
        } else {
            @()
        }

        [ModuleMetadataInfo]@{
            ScriptFiles = $scriptFiles
            PublicFunctionNames = $publicFunctionNames
            Resources = $resourcesFile
        }
    }
}
