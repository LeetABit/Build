#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Diagnostics.CodeAnalysis

Set-StrictMode -Version 3

function Convert-ArgumentValue {
    <#
    .SYNOPSIS
        Conditionally converts a specified argument to a [Switch] type.
    .PARAMETER Value
        Argument to convert.
    .PARAMETER IsSwitch
        Indicates whether the argument shall be threated as a value for [Switch] parameter.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([Object[]])]

    [SuppressMessageAttribute(
        'PSReviewUnusedParameter',
        'IsSwitch',
        Justification = 'False positive as rule does not scan child scopes: https://github.com/PowerShell/PSScriptAnalyzer/issues/1472')]
    param (
        [Parameter(HelpMessage = 'Provide argument value.',
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [Object[]]
        $Value,

        [Parameter(Position=1,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [Switch]
        $IsSwitch)

    process {
        $Value | ForEach-Object {
            if ($IsSwitch) {
                if ($_) {
                    [Switch][Boolean]$_
                } else {
                    [Switch]$True
                }
            }
            else {
                $_
            }
        }
    }
}
