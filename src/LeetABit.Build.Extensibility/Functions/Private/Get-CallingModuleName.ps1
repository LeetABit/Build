#requires -version 6

Set-StrictMode -Version 3.0

function Get-CallingModuleName {
    <#
    .SYNOPSIS
        Gets the name of the module in which the specified script blocks are defined or the nearest module on the call stack.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Name of the extension for which the project resolver shall be unregistered.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [ScriptBlock[]]
        $Scripts
    )

    process {
        $uniqueModules = @($Scripts | ForEach-Object {
            if ($_ -and $_ -is [scriptblock] -and $_.Module -and ($_.Module.Name -ne 'LeetABit.Build.Extensibility')) {
                $_.Module.Name
            }
        } | Sort-Object | Get-Unique)

        if ($uniqueModules -and ($uniqueModules | Measure-Object).Count -eq 1) {
            $result = $uniqueModules[0]
        }
        else {
            [ScriptBlock]$scriptBlock = Get-PSCallStack | Select-Object -Skip 1 | Foreach-Object {
                $_.InvocationInfo.MyCommand.ScriptBlock
            } | Where-Object {
                $_ -and $_.Module -and $_.Module.Name -ne 'LeetABit.Build.Extensibility'
            } | Select-Object -First 1

            if ($scriptBlock) {
                $result = $scriptBlock.Module.Name
            }
        }

        if ($result -eq "LeetABit.Build") {
            $result = 'LeetABit.Build.Repository'
        }

        if ($result) {
            $result
        }
    }
}
