#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Diagnostics.CodeAnalysis
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Set-StrictMode -Version 3.0

function Get-DynamicParameters {
    <#
    .SYNOPSIS
        Gets dynamic parameters for all extensions registered in the LeetABit.Build system.
    #>
    [CmdletBinding()]
    [OutputType([RuntimeDefinedParameterDictionary[]])]
    param (
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {

        $parameterTypeName = 'System.Management.Automation.RuntimeDefinedParameter'
        $attributes = New-Object -Type System.Management.Automation.ParameterAttribute
        $attributes.Mandatory = $false
        $result = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary

        LeetABit.Build.Extensibility\Get-BuildExtension | ForEach-Object {
            $extensionPrefix = $($_.Name.Replace('.', [String]::Empty))

            ForEach-Object { $_.Tasks.Values } |
            ForEach-Object { $_.Jobs } |
            ForEach-Object {
                if ($_ -is [ScriptBlock]) {
                    $paramBlock = if ($_.Ast | Get-Member 'ParamBlock') {
                        $_.Ast.ParamBlock
                    } elseif ($_.Ast | Get-Member 'Body') {
                        $_.Ast.Body.ParamBlock
                    } else {
                        $null
                    }

                    if ($paramBlock) {
                        $paramBlock.Parameters | ForEach-Object {
                            $parameterAst = $_
                            $parameterName = $_.Name.VariablePath.UserPath

                            ($parameterName, "$($extensionPrefix)_$parameterName") | ForEach-Object {
                                if (-not ($result.Keys -contains $_)) {
                                    $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
                                    $attributeCollection.Add($attributes)
                                    $parameterAst.Attributes | ForEach-Object {
                                        if ($_.TypeName.Name -eq "ArgumentCompleter" -or $_.TypeName.Name -eq "ArgumentCompleterAttribute") {
                                            $commonArgument = if ($_.PositionalArguments.Count -gt 0) {
                                                $_.PositionalArguments[0]
                                            }
                                            else {
                                                $_.NamedArguments[0].Argument
                                            }

                                            $completerParameter = if ($commonArgument -is [ScriptBlockExpressionAst]) {
                                                $commonArgument.ScriptBlock.GetScriptBlock()
                                            }
                                            else {
                                                $commonArgument.StaticType
                                            }

                                            $autocompleterAttribute = New-Object -Type System.Management.Automation.ArgumentCompleterAttribute $completerParameter
                                            $attributeCollection.Add($autocompleterAttribute)
                                        }
                                    }

                                    $dynamicParam = New-Object -Type $parameterTypeName ($_, $parameterAst.StaticType, $attributeCollection)
                                    $result.Add($dynamicParam.Name, $dynamicParam)
                                }
                            }
                        }
                    }
                }
            }
        }

        $result
    }
}
