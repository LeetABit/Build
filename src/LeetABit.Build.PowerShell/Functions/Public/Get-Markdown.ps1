#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Get-Markdown {
    <#
    .SYNOPSIS
        Gets text that represents a markdown document for the specified PowerShell help object.
    .PARAMETER HelpObject
        Custom object that represents command help.
    #>

    [CmdletBinding(PositionalBinding = $False)]

    param (
        [Parameter(Position = 0,
                Mandatory = $True,
                ValueFromPipeline = $True,
                ValueFromPipelineByPropertyName = $True)]
        [PSCustomObject]
        $HelpObject
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        Set-StrictMode -Off
    }

    process {
        try {
            $name = $HelpObject.Name

            if ($name -and [System.IO.Path]::IsPathRooted($name)) {
                $name = Split-Path $name -Leaf
            }

            Write-Output "# $name"
            Write-Output ""
            Write-Output "$($HelpObject.Synopsis)"

            $HelpObject.Syntax.SyntaxItem | ForEach-Object {
                $syntax = $_.Name

                if ($syntax -and [System.IO.Path]::IsPathRooted($syntax)) {
                    $syntax = Split-Path $syntax -Leaf
                }

                $syntax = "``````$syntax"

                if ($_.psobject.Properties.name -match "Parameter") {
                    $_.Parameter | ForEach-Object {
                        $optional = $_.required -ne 'true'
                        $positional = (($_.position -ne $()) -and ($_.position -ne '') -and ($_.position -notmatch 'named') -and ([int]$_.position -ne $()))
                        $parameterValue = ''
                        if ($_.psobject) {
                            $parameterValue = if ($null -ne $_.psobject.Members['ParameterValueGroup']) {
                                " {$($_.ParameterValueGroup.ParameterValue -join ' | ')}"
                            } elseif ($null -ne $_.psobject.Members['ParameterValue']) {
                                " <$($_.ParameterValue)>"
                            }
                        }

                        $value = $(if ($optional -and $positional) { ' [[-{0}]{1}]' }
                        elseif ($optional)   { ' [-{0}{1}]' }
                        elseif ($positional) { ' [-{0}]{1}' }
                        else                 { ' -{0}{1}' }) -f $_.Name, $parameterValue

                        $syntax += $value
                    }
                }

                $syntax += "``````"
                Write-Output ""
                Write-Output $syntax
            }

            if ($HelpObject.psobject.Properties.name -match "Description" -and $HelpObject.Description) {
                Write-Output ""
                Write-Output "## Description"
                Write-Output ""
                Write-Output "$($HelpObject.Description.Text)"
            }

            $exampleNumber = 1;
            if ((Get-Member -InputObject $HelpObject -Name "Examples") -and ($HelpObject.Examples) -and (Get-Member -InputObject ($HelpObject.Examples) -Name "Example")) {
                Write-Output ""
                Write-Output "## Examples"
                $HelpObject.Examples.Example | ForEach-Object {
                    Write-Output ""
                    Write-Output "### Example $exampleNumber`:"
                    Write-Output ""
                    Write-Output "``````$($_.Introduction.Text) $($_.Code)``````"
                    Write-Output ""
                    Write-Output $($_.Remarks.Text -replace "#`>", "#>" -join [System.Environment]::NewLine).TrimEnd()
                    $exampleNumber += 1
                }
            }

            Write-Output ""
            Write-Output "## Parameters"
            if ($HelpObject.Parameters.psobject.Properties.name -match "Parameter") {
                $HelpObject.Parameters.Parameter | ForEach-Object {
                    Write-Output ""
                    Write-Output "### ``````-$($_.Name)``````"
                    $_ | Select-Object -Property Description | ForEach-Object {
                        if ($_.Description) {
                            Write-Output ""
                            Write-Output "*$($_.Description.Text)*"
                        }
                    }

                    Write-Output ""
                    Write-Output "<table>"
                    Write-Output "  <tr><td>Type:</td><td>$($_.Type.Name)</td></tr>"
                    Write-Output "  <tr><td>Required:</td><td>$($_.Required)</td></tr>"
                    Write-Output "  <tr><td>Position:</td><td>$((Get-Culture).TextInfo.ToTitleCase($_.Position))</td></tr>"
                    Write-Output "  <tr><td>Default value:</td><td>$($_.DefaultValue)</td></tr>"
                    Write-Output "  <tr><td>Accept pipeline input:</td><td>$($_.PipelineInput)</td></tr>"
                    Write-Output "  <tr><td>Accept wildcard characters:</td><td>$($_.Globbing)</td></tr>"
                    Write-Output "</table>"
                }
            }

            Write-Output ""
            Write-Output "## Input"
            if (Get-Member -InputObject $HelpObject -Name "InputTypes") {
                $HelpObject.InputTypes | ForEach-Object {
                    Write-Output ""
                    Write-Output "``````[$($_.InputType.Type.Name.Trim())]``````"
                }
            }
            else {
                Write-Output ""
                Write-Output "None"
            }

            Write-Output ""
            Write-Output "## Output"
            if (Get-Member -InputObject $HelpObject -Name "ReturnValues") {
                $HelpObject.ReturnValues | ForEach-Object {
                    Write-Output ""
                    Write-Output "``````[$($_.ReturnValue.Type.Name.Trim())]``````"
                }
            }
            else {
                Write-Output ""
                Write-Output "None"
            }

            if ((Get-Member -InputObject $HelpObject -Name "Notes") -or (Get-Member -InputObject $HelpObject -Name "AlertSet")) {
                Write-Output ""
                Write-Output "## Notes"
                if (Get-Member -InputObject $HelpObject -Name "Notes") {
                    Write-Output ""
                    Write-Output "$HelpObject.Notes"
                }

                if (Get-Member -InputObject $HelpObject -Name "AlertSet") {
                    foreach ($alert in $HelpObject.AlertSet) {
                        foreach ($alertItem in $alert.alert) {
                            Write-Output ""
                            Write-Output $alertItem.Text
                        }
                    }
                }
            }

            if (Get-Member -InputObject $HelpObject -Name "RelatedLinks") {
                Write-Output ""
                Write-Output "## Related Links"
                $HelpObject.RelatedLinks.NavigationLink | ForEach-Object {
                    Write-Output ""
                    if ($_.LinkText -notmatch "^about_") {
                        Write-Output "[$($_.LinkText)]($(($_.LinkText) -replace "\\", "/").md)"
                    }
                    else {
                        Write-Output "[$($_.LinkText)](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/$($_.LinkText))"
                    }
                }
            }
        }
        finally {
            Set-StrictMode -Version 3.0
        }
    }
}
