#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections
using namespace System.Management.Automation

Set-StrictMode -Version 3

function Select-CommandArgumentSet {
    <#
    .SYNOPSIS
        Selects a collection of arguments that match specified command parameters.
    .DESCRIPTION
        Select-CommandArgumentSet cmdlet tries to find parameters for the specified command, script block or parameter collection. The cmdlet is looking for a variables which name matches one of the following case-insensitive patterns: `LeetABitBuild_$ExtensionName_$ParameterName`, `$ExtensionName_$ParameterName`, `LeetABitBuild_$ParameterName`, `{ParameterName}`. Any dots in the name are ignored. There are four different argument sources, listed below in a precedence order:
        1. Dictionary of arguments specified as value for AdditionalArguments parameter.
        2. Arguments provided via Set-CommandArgumentSet and Add-CommandArgument cmdlets.
        3. Values stored in 'LeetABit.Build.json' file located in the repository root directory provided via Set-CommandArgumentSet cmdlet or on of its subdirectories.
        4. Environment variables.
    .PARAMETER Command
        Command for which a matching arguments shall be selected.
    .PARAMETER ScriptBlock
        Script block for which a matching arguments shall be selected.
    .PARAMETER ParameterSets
        Collection of the parameter sets for which a matching arguments shall be selected.
    .PARAMETER ExtensionName
        Name of the build extension for which the arguments shall be selected.
    .PARAMETER AdditionalArguments
        Dictionary of additional arguments that shall be used as a source of parameter's values.
    .EXAMPLE
        PS> Select-CommandArgumentSet -Command (Get-Command LeetABit.Build.PowerShell\Deploy-Project)

        Tries to selects arguments for a Get-Command LeetABit.Build.PowerShell\Deploy-Project command.
    .EXAMPLE
        PS> Select-CommandArgumentSet -ScriptBlock $script -ExtensionName "LeetABit.Build.PowerShell" -AdditionalArguments $arguments

        Tries to selects arguments for a script block defined in "LeetABit.Build.PowerShell" module with an additional arguments specified as a parameter.
    .EXAMPLE
        PS> Select-CommandArgumentSet -ParameterSets (Get-Command LeetABit.Build.PowerShell\Deploy-Project).ParameterSets

        Tries to selects arguments for a Get-Command LeetABit.Build.PowerShell\Deploy-Project command via its parameter sets.
    .NOTES
        Select-CommandArgumentSet cmdlet tries to match each of the command's parameter set till it finds the first satisfied completely.
        If no parameter set is satisfied with the current arguments provided to the module this cmdlet emits an error message.
    .LINK
        Add-CommandArgument
    .LINK
        Set-CommandArgumentSet
    #>
    [CmdletBinding(PositionalBinding = $False,
                   DefaultParameterSetName = "Command")]
    [OutputType([Object[]])]

    param (
        [Parameter(HelpMessage = 'Provide command info object for which arguments shall be selected.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = "Command")]
        [CommandInfo]
        $Command,

        [Parameter(HelpMessage = 'Provide script block object for which arguments shall be selected.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = "ScriptBlock")]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = "Manual")]
        [CommandParameterSetInfo[]]
        $ParameterSets,

        [Parameter(Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = "Command")]
        [Parameter(Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = "ScriptBlock")]
        [Parameter(Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = "Manual")]
        [String]
        $ExtensionName,

        [Parameter(Position = 2,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False,
                   ParameterSetName = "Command")]
        [Parameter(Position = 2,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False,
                   ParameterSetName = "ScriptBlock")]
        [Parameter(Position = 2,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False,
                   ParameterSetName = "Manual")]
        [IDictionary]
        $AdditionalArguments
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Command') {
            $ParameterSets = $Command.ParameterSets

            if (-not $ExtensionName -and $Command.ModuleName) {
                $ExtensionName = $Command.ModuleName
            }
        } elseif ($PSCmdlet.ParameterSetName -eq 'ScriptBlock') {
            $paramBlock = if ($ScriptBlock.Ast | Get-Member 'ParamBlock') {
                $ScriptBlock.Ast.ParamBlock
            } elseif ($ScriptBlock.Ast | Get-Member 'Body') {
                $ScriptBlock.Ast.Body.ParamBlock
            } else {
                $null
            }

            if ($paramBlock) {
                $function:private:ScriptBlockCommand = $ScriptBlock
                $commandFunction = Get-Command -Name ScriptBlockCommand -Type Function
                $ParameterSets = $commandFunction.ParameterSets
            }

            if (-not $ExtensionName -and $ScriptBlock.Module) {
                $ExtensionName = $ScriptBlock.Module.Name
            }
        }

        $errors = @()
        $namedArguments = @{}
        $positionalArguments = @()
        $found = $false
        $mostWideParameterSet = $null
        $mostWideParameterSetName = $Null

        foreach ($parameterSet in $parameterSets) {
            try {
                $currentNamedArguments, $currentPositionalArguments = Select-CommandArgumentSetCore -Parameters $parameterSet.Parameters -ExtensionName $ExtensionName -AdditionalArguments $AdditionalArguments
            }
            catch {
                if ($parameterSet.Name -eq $AllParameterSets) {
                    $errors += $_.Exception.Message
                }
                else {
                    $errors += "{0}: {1}" -f $parameterSet.Name, $_.Exception.Message
                }

                continue
            }

            $found = $true
            $currentParameterNames = $parameterSet.Parameters | Foreach-Object { $_.Name }
            $currentParameterSetName = $parameterSet.Name
            if (-not $mostWideParameterSet) {
                $mostWideParameterSet = $currentParameterNames
                $mostWideParameterSetName = $currentParameterSetName
                $namedArguments = $currentNamedArguments
                $positionalArguments = $currentPositionalArguments
            }
            else {
                $union = $mostWideParameterSet + $currentParameterNames | Sort-Object | Get-Unique
                if ($union.Length -gt [Math]::Max($mostWideParameterSet.Length, $currentParameterNames.Length)) {
                    throw $LocalizedData.Error_SelectCommandArgumentSet_Reason -f
                        ($LocalizedData.Reason_MultipleParameterSetsMatch_FirstParameterSet_SecondParameterSet -f $mostWideParameterSetName, $currentParameterSetName)
                }
                elseif ($currentParameterNames.Length -gt $mostWideParameterSet.Length) {
                    $mostWideParameterSet = $currentParameterNames
                    $mostWideParameterSetName = $currentParameterSetName
                    $namedArguments = $currentNamedArguments
                    $positionalArguments = $currentPositionalArguments
                }
            }
        }

        if (-not $found -and $parameterSets) {
            throw $LocalizedData.Error_SelectCommandArgumentSet_Reason -f
                ($LocalizedData.Reason_NoMatchingParameterSetFound_NewLine_Errors -f [Environment]::NewLine, ($errors -join [Environment]::NewLine))
        }

        $namedArguments
        Write-Output -InputObject $positionalArguments -NoEnumerate
    }
}
