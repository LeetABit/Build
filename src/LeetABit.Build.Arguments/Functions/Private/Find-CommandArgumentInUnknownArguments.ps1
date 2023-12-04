#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3

function Find-CommandArgumentInUnknownArguments {
    <#
    .SYNOPSIS
        Examines a collection of arguments which kind has not yet been determined for presence of a specified named parameter's value.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([Object])]

    param (
        # Name of the parameter.
        [Parameter(HelpMessage = 'Provide parameter name.',
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [String]
        $ParameterName,

        # Indicates whether the argument shall be threated as a value for [Switch] parameter.
        [Parameter(Position=1,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [Switch]
        $IsSwitch
    )

    process {
        for ($i = 0; $i -lt $script:UnknownArguments.Count; ++$i) {
            $unknownCandidate = $script:UnknownArguments[$i]
            $hasNextArgument = ($i + 1) -lt $script:UnknownArguments.Count
            if ($hasNextArgument) {
                $nextCandidate = $script:UnknownArguments[$i + 1]
            } elseif (-Not ($IsSwitch)) {
                break
            }

            $candidateParameterName = Select-ParameterName $unknownCandidate
            if ($candidateParameterName -eq $ParameterName) {
                $simpleSwitch = $False

                if ($IsSwitch) {
                    if ($unknownCandidate.EndsWith(':')) {
                        if ($hasNextArgument) {
                            if (($nextCandidate -eq 'True') -or ($nextCandidate -eq 'False')) {
                                $result = [Switch][System.Boolean]$nextCandidate
                            }
                        }
                    } else {
                        $result = [Switch]$True
                        $simpleSwitch = $True
                    }
                } else {
                    $result = $nextCandidate
                }

                $script:NamedArguments[$ParameterName] = $result
                $script:UnknownArguments.RemoveAt($i)
                if (-not $simpleSwitch) { $script:UnknownArguments.RemoveAt($i) }
                if ($i -eq 0)           { Pop-PositionalArguments              }
                $script:NamedArguments[$ParameterName]
                return
            }
        }
    }
}
