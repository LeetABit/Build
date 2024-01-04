#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

using namespace System
using namespace System.Collections
using namespace System.Management.Automation

Set-StrictMode -Version 3.0

function ConvertTo-ExpressionString {
    <#
    .SYNOPSIS
        Converts an object to a PowerShell expression string with a specified indentation.
    .DESCRIPTION
        The ConvertTo-ExpressionString cmdlet converts any object to its type's string representation.
        Dictionaries and PSObjects are converted to hash literal expression format.
        The field and properties are converted to key expressions,
        the field and properties values are converted to property values,
        and the methods are removed. Objects that implements IEnumerable are converted to array
        literal expression format.
    .PARAMETER InputObject
        Input object to convert.
    .PARAMETER IndentationLevel
        Number of spaces to perpend to each line of the resulting string.
    .PARAMETER Minify
        Determines whether the output string shall be minified to reduce its size.
    .EXAMPLE
        ConvertTo-ExpressionString -InputObject $Null, $True, $False
        $Null
        $True
        $False

        Converts PowerShell literals expression string.
    .EXAMPLE
        ConvertTo-ExpressionString -InputObject @{Name = "Custom object instance"}
        @{
          'Name' = 'Custom object instance'
        }

        Converts hashtable to PowerShell hash literal expression string.
    .EXAMPLE
        ConvertTo-ExpressionString -InputObject @( $Name )
        @(
          $Null
        )

        Converts array to PowerShell array literal expression string.
    .EXAMPLE
        ConvertTo-ExpressionString -InputObject (New-PSObject "SampleType" @{Name = "Custom object instance"})
        <# SampleType #`>
        @{
          'Name' = 'Custom object instance'
        }

        Converts custom PSObject to PowerShell hash literal expression string with a custom type name in the comment block.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   DefaultParameterSetName = 'Indentation',
                   HelpUri = '$LeetABit_ReferenceDoc_GitHubLink')]
    [OutputType([String])]

    param (
        [Parameter(HelpMessage = 'Provide an object to convert.',
                   Position = 0,
                   Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [Object]
        $InputObject,

        [Parameter(ParameterSetName = 'Indentation')]
        [AllowNull()]
        [String]
        $Indentation = '',

        [Parameter(ParameterSetName = 'Indentation')]
        [AllowNull()]
        [String]
        $AdditionalIndentation = ' ',

        [Parameter(ParameterSetName = 'Indentation')]
        [Switch]
        $SkipFirstLineIndentation,

        [Parameter(ParameterSetName = 'Minify')]
        [Switch]
        $Minify
    )

    begin {
        if ($Minify) {
            $firstLineIdnentation = ''
            $itemsSpace = ''
            $recursiveParams = @{
                'Minify' = $True
            }

            $joinParams = @{
                'Minify' = $True
            }
        } else {
            $firstLineIdnentation = if ($SkipFirstLineIndentation) { '' } else { $Indentation }
            $itemsSpace = ' '
            $recursiveParams = @{
                'Indentation' = "$Indentation$AdditionalIndentation"
                'AdditionalIndentation' = $AdditionalIndentation
                'SkipFirstLineIndentation' = $True
            }

            $joinParams = @{
                'Indentation' = "$Indentation"
                'AdditionalIndentation' = $AdditionalIndentation
                'SkipFirstLineIndentation' = $SkipFirstLineIndentation
            }
        }
    }

    process {
        if ($Null -eq $InputObject) {
            '$Null'
        }
        elseif ($InputObject -is [String]) {
            if ($InputObject -contains '`r' -or $InputObject -contains '`n') {
                "$firstLineIdnentation@""$([Environment]::NewLine)$InputObject$([Environment]::NewLine)""@"
            } else {
                "$firstLineIdnentation'$InputObject'"
            }
        }
        elseif ($InputObject -is [SwitchParameter] -or $InputObject -is [Boolean]) {
            "$firstLineIdnentation`$$InputObject"
        }
        elseif ($InputObject -is [IDictionary]) {
            $InputObject.Keys | ForEach-Object {
                $propertyName = ConvertTo-ExpressionString $_ @recursiveParams
                $propertyValue = ConvertTo-ExpressionString $InputObject[$_] @recursiveParams
                "$propertyName$itemsSpace=$itemsSpace$propertyValue"
            } | Join-StringItems -Prefix '@{' -Suffix '}' -ItemSeparator ";" @joinParams
        }
        elseif ($InputObject -is [PSCustomObject]) {
            $result = ''

            $SkipObjectFirstLineIndentation = $SkipFirstLineIndentation
            if (-not $Minify) {
                $types = $InputObject.PSObject.TypeNames | Where-Object {
                    $_ -ne "Selected.System.Management.Automation.PSCustomObject" -and
                    $_ -ne "System.Management.Automation.PSCustomObject" -and
                    $_ -ne "System.Object"
                }

                if ($types) {
                    $SkipObjectFirstLineIndentation = $false
                    $result = $types | ForEach-Object {
                        "[$_]"
                    } | Join-StringItems -Prefix '<#' -Suffix '#>' -ItemSeparator "," @joinParams

                    if ($result) {
                        $result += [Environment]::NewLine
                    }
                }
            }

            Get-Member -InputObject $InputObject -MemberType NoteProperty | ForEach-Object {
                $name = $_.Name
                $value = $InputObject | Select-Object -ExpandProperty $name | ConvertTo-ExpressionString @recursiveParams
                "'$name'$itemsSpace=$itemsSpace$value"
            } | Join-StringItems -Prefix '@{' -Suffix '}' -ItemSeparator ";" @joinParams -SkipFirstLineIndentation:$SkipObjectFirstLineIndentation
        } elseif ($InputObject -is [IEnumerable]) {
            $items = @()
            foreach ($item in $InputObject) {
                $items += ConvertTo-ExpressionString -InputObject $item @recursiveParams
            }

            $items | Join-StringItems -Prefix '@(' -Suffix ')' -ItemSeparator "," @joinParams
        } else {
            [String]$InputObject
        }
    }
}
