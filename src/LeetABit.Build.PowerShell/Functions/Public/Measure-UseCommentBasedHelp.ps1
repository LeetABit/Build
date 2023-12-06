#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using module PSScriptAnalyzer
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

Set-StrictMode -Version 3.0

function Measure-UseCommentBasedHelp {
    <#
    .SYNOPSIS
        Functions and script files should have help comments.
    .DESCRIPTION
        Functions and script files should have a text-based help comments provided to assist users and maintainers in understanding its purpose and behavior.
    .PARAMETER ScriptBlockAst
        Script block's AST to analyze
    .EXAMPLE
        PS> Measure-UseCommentBasedHelp -ScriptBlockAst $ScriptBlockAst

        Gets rule violations found in the specified script block.
    .OUTPUTS
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
    #>
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]

    param (
        [Parameter(HelpMessage = "Provide script block's AST to analyze.",
                   Mandatory = $true)]
        [ValidateNotNull()]
        [ScriptBlockAst]
        $ScriptBlockAst
    )

    begin {
        $ruleName = $PSCmdlet.MyInvocation.MyCommand.Name.Replace('Measure-', '')
    }

    process {
        $results = @()
        foreach ($functionAst in $ScriptBlockAst.FindAll((Get-Command Test-FunctionDefinition).ScriptBlock, $true)) {
            $functionWarnings = @()
            $help = $functionAst.GetHelpContent()
            if (-not $help) {
                $functionWarnings += "Function '$($functionAst.Name)' missing documentation comment block."
                continue
            }
            else {
                if (-not $help.Synopsis) {
                    $functionWarnings += "Function '$($functionAst.Name)' missing .SYNOPSIS documentation block."
                }

               if (-not $help.Outputs) {
                   if ($functionAst.Body.Attributes | Where-Object {
                       $_ -is [OutputType]
                   }) {
                       $functionWarnings += "Function '$($functionAst.Name)' missing .OUTPUTS documentation block."
                   }
               }

               $parametersInHelp = $Help.Parameters.Keys
               $parametersInFunction = @()

               foreach ($paramBlockAst in $functionAst.FindAll((Get-Command Test-ParamBlock).ScriptBlock, $true)) {
                  foreach ($paramAst in $paramBlockAst.Parameters) {
                      $parametersInFunction += $paramAst.Name.VariablePath.UserPath
                      foreach ($attributeAst in $paramAst.Attributes) {
                          $attributeType = $attributeAst.TypeName.GetReflectionAttributeType()
                          if ($attributeType -and $attributeType -eq [ParameterAttribute]) {
                              $mandatoryArgument = $attributeAst.NamedArguments | Where-Object { $_.ArgumentName -eq "Mandatory"}
                              $helpMessage = $attributeAst.NamedArguments | Where-Object { $_.ArgumentName -eq "HelpMessage" -or $_.ArgumentName -eq "HelpMessageBaseName" -or $_.ArgumentName -eq "HelpMessageResourceId"}
                              if ($mandatoryArgument -and $mandatoryArgument.Argument -is [VariableExpressionAst] -and $mandatoryArgument.Argument.VariablePath.UserPath -eq 'True' -and -not $helpMessage) {
                                  $functionWarnings += "Function '$($functionAst.Name)' is missing help message for mandatory parameter '$($paramAst.Name.VariablePath.UserPath)'."
                              }
                          }
                      }
                  }
               }

               foreach ($dynamicParamAst in $functionAst.FindAll((Get-Command Test-DynamicParamBlock).ScriptBlock, $true)) {
                  $parametersInFunction += (Invoke-Command -Scriptblock ($dynamicParamAst.Statements.ScriptBlock)).Keys
               }

               foreach ($functionParam in $parametersInFunction) {
                  if ($ParametersInHelp -inotcontains $functionParam) {
                      $functionWarnings += "Function '$($functionAst.Name)' missing .PARAMETER documentation for parameter '$FunctionParam'."
                  }
               }

               foreach ($helpParam in $parametersInHelp) {
                  if ($parametersInFunction -inotcontains $helpParam) {
                      $functionWarnings += "Function '$($functionAst.Name)' has .PARAMETER documentation for non-existing parameter '$FunctionParam'."
                  }
               }
            }

            $results += ($functionWarnings | ForEach-Object { [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
               'Message'  = $_
               'Extent'   = $functionAst.Extent
               'RuleName' = $ruleName
               'Severity' = 'Warning'
            }})
        }

        return $results
    }
}

function Test-FunctionDefinition {
    param (
        [Ast]
        $Ast
    )

    process {
        $Ast -is [FunctionDefinitionAst]
    }
}

function Test-ParamBlock {
    param (
        [Ast]
        $Ast
    )

    process {
        $Ast -is [ParamBlockAst]
    }
}

function Test-DynamicParamBlock {
    param (
        [Ast]
        $Ast
    )

    process {
        ($Ast -is [NamedBlockAst]) -and ($Ast.BlockKind -eq [TokenKind]::Dynamicparam)
    }
}
