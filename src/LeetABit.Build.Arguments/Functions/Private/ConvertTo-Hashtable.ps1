#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3

function ConvertTo-Hashtable {
    <#
    .SYNOPSIS
        Converts an input object to a HAshtable.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([Hashtable])]
    param (
        # Object to convert.
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
            }
        } elseif ($InputObject -is [PSObject]) {
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
