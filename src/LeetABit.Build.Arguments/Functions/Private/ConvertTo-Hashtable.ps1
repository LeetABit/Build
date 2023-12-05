#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections

Set-StrictMode -Version 3

function ConvertTo-Hashtable {
    <#
    .SYNOPSIS
        Converts an input object to a HAshtable.
    .PARAMETER InputObject
        Object to convert.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([Hashtable])]
    param (
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [Object]
        [AllowNull()]
        $InputObject
    )

    process {
        if ($Null -eq $InputObject -or $InputObject -is [IDictionary]) {
            $InputObject
        }
        elseif ($InputObject -is [IEnumerable] -and $InputObject -isnot [string]) {
            $InputObject | ForEach-Object {
                ConvertTo-Hashtable -InputObject $_
            } | Write-Output -NoEnumerate
        } elseif ($InputObject -is [PSObject] -and $InputObject -isnot [string]) {
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }

            $hash
        } else {
            $InputObject
        }
    }
}
