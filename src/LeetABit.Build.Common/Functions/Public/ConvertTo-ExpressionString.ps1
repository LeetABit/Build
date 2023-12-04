#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections

Set-StrictMode -Version 3.0

function ConvertTo-ExpressionString {
    <#
    .SYNOPSIS
        Converts an object to a PowerShell expression string with a specified indentation.
    .DESCRIPTION
        The ConvertTo-ExpressionStringWithIndentation cmdlet converts any .NET object to a object type's defined string representation.
        Dictionaries and PSObjects are converted to hash literal expression format. The field and properties are converted to key expressions,
        the field and properties values are converted to property values, and the methods are removed. Objects that implements IEnumerable
        are converted to array literal expression format.
        Each line of the resulting string is indented by the specified number of spaces.
    .EXAMPLE
        ConvertTo-ExpressionString -Obj $Null, $True, $False
        $Null
        $True
        $False

        Converts PowerShell literals expression string.
    .EXAMPLE
        ConvertTo-ExpressionString -Obj @{Name = "Custom object instance"}
        @{
          'Name' = 'Custom object instance'
        }

        Converts hashtable to PowerShell hash literal expression string.
    .EXAMPLE
        ConvertTo-ExpressionString -Obj @( $Name )
        @(
          $Null
        )

        Converts array to PowerShell array literal expression string.
    .EXAMPLE
        ConvertTo-ExpressionString -Obj (New-PSObject "SampleType" @{Name = "Custom object instance"})
        <# SampleType #`>
        @{
          'Name' = 'Custom object instance'
        }

        Converts custom PSObject to PowerShell hash literal expression string with a custom type name in the comment block.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String])]

    param (
        # Object to convert.
        [Parameter(HelpMessage = 'Provide an object to convert.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [Object]
        $Obj,

        # Number of spaces to perpend to each line of the resulting string.
        [Parameter(HelpMessage = 'Provide an indentation level.',
                   Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [ValidateRange([ValidateRangeKind]::NonNegative)]
        [Int32]
        $IndentationLevel = 0
    )

    process {
        $prefix = " " * $IndentationLevel

        if ($Null -eq $Obj) {
            '$Null'
        }
        elseif ($Obj -is [String]) {
            "'$Obj'"
        }
        elseif ($Obj -is [SwitchParameter] -or $Obj -is [Boolean]) {
            "`$$Obj"
        }
        elseif ($Obj -is [IDictionary]) {
            $result = "@{"
            $Obj.Keys | ForEach-Object {
                $value = ConvertTo-ExpressionString $Obj[$_] ($IndentationLevel + 2)
                $result += [Environment]::NewLine + "$prefix  '$_' = $value; "
            }

            $result = $result.Substring(0, $result.Length - 2)
            $result += [Environment]::NewLine + "$prefix}"
            $result
        }
        elseif ($Obj -is [PSCustomObject]) {
            $result = ""

            if ($Obj.PSObject.TypeNames.Count -gt 0) {
                $result += "<# "
                $Obj.PSObject.TypeNames | ForEach-Object {
                    if ($_ -ne "Selected.System.Management.Automation.PSCustomObject" -and
                        $_ -ne "System.Management.Automation.PSCustomObject" -and
                        $_ -ne "System.Object") {
                        $result += "[$_], "
                    }
                }

                $result = $result.Substring(0, $result.Length - 2)
                $result += " #>"
                $result += [Environment]::NewLine
            }

            $result += "@{"
            Get-Member -InputObject $Obj -MemberType NoteProperty | ForEach-Object {
                $value = $Obj | Select-Object -ExpandProperty $_.Name
                $value = ConvertTo-ExpressionString $value ($IndentationLevel + 1)
                $result += [Environment]::NewLine + "$prefix  '$($_.Name)' = $value; "
            }

            $result = $result.Substring(0, $result.Length - 2)
            $result += [Environment]::NewLine + "$prefix}"
            $result
        }
        elseif ($Obj -is [IEnumerable]) {
            $result = "("
            $Obj | ForEach-Object {
                $value = ConvertTo-ExpressionString $_ ($IndentationLevel + 1)
                $result += [Environment]::NewLine + "$prefix  $value, "
            }

            $result = $result.Substring(0, $result.Length - 2)
            $result += [Environment]::NewLine + "$prefix)"
            $result
        }
        else {
            [String]$Obj
        }
    }
}
