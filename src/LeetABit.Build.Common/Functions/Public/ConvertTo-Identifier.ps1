#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function ConvertTo-Identifier {
    <#
    .SYNOPSIS
        Converts a string to an identifier be removing all invalid characters.
    .DESCRIPTION
        ConvertTo-Identifier cmdlet creates an identifier from the specified string value by replacing all characters that are not letter, digit or underscore with underscore.
        When the value does not start with letter or underscore this cmdlet inserts an underscore character at the beginning of the result.
    .EXAMPLE
        PS> ConvertTo-Identifier ""

        Returns an underscore as an identifier created from an empty string.
    .EXAMPLE
        PS> ConvertTo-Identifier "Convert this"

        Returns "Convert_this" string as an identifier created from the input value.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String])]

    param (
        # String to convert.
        [Parameter(HelpMessage = 'Provide a string to convert.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $Value
    )

    begin {
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if (-not $Value) {
            '_'
            return
        }

        if ($Value[0] -match '"[^a-z_]') {
            $Value = "_$Value"
        }

        $Value -replace '[^a-z0-9_]', '_'
    }
}
