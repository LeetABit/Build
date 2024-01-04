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

function Join-StringItems {
    <#
    .SYNOPSIS
        Combines items into a collection representation.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   DefaultParameterSetName = 'Indent')]
    [OutputType([String])]

    param (
        [Parameter(Position = 0,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [Object[]]
        $InputObject,

        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [String]
        $Prefix,

        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [String]
        $Suffix,

        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [String]
        $ItemSeparator,

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
        $content = ''
        $count = 0
        if ($Minify) {
            $prefixIdnentation = ''
            $suffixIndentation = ''
            $itemsSpace = ''
        } else {
            $prefixIdnentation = if ($SkipFirstLineIndentation) { '' } else { $Indentation }
            $suffixIndentation = $Indentation
            $itemsSpace = ' '
        }

        $separator = "$ItemSeparator$itemsSpace"
        $itemsIdnentation = "$Indentation$AdditionalIndentation"
    }

    process {
        $InputObject | ForEach-Object {
            $count = $count + 1
            if ($count -ge 2) {
                if ($count -eq 2) {
                    $content = $content.Substring(0, $content.Length - $separator.Length)
                }

                $content += "$([Environment]::NewLine)$itemsIdnentation$_"
            } else {
                $content += "$_$separator"
            }
        }
    }

    end {
        if ($content) {
            if ($count -ge 2) {
                "$prefixIdnentation$Prefix$([Environment]::NewLine)$itemsIdnentation$content$([Environment]::NewLine)$suffixIndentation$Suffix"
            } else {
                $content = $content.Substring(0, $content.Length - $separator.Length)
                "$prefixIdnentation$Prefix$content$Suffix"
            }
        } else {
            "$prefixIdnentation$Prefix$Suffix"
        }
    }
}
