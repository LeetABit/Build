#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Management.Automation

Set-StrictMode -Version 3.0

function Write-Invocation {
    <#
    .SYNOPSIS
        Writes a verbose message about the specified invocation.
    .DESCRIPTION
        Write-Invocation cmdlet writes a message to a verbose stream that contains information about executing function invocation.
    .EXAMPLE
        Write-Invocation $MyInvocation

        Writes a verbose information about current function invocation.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Invocation which information shall be written.
        [Parameter(HelpMessage = "Provide invocation information about the command to write to verbose log.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [ValidateNotNull()]
        [InvocationInfo]
        $Invocation
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $message = $LocalizedData.Write_Invocation_ExecutingCommandWithParameters_CommandName
        $message = $message -f ($Invocation.MyCommand.ModuleName, $Invocation.MyCommand.Name)
        Write-Verbose $message

        $Invocation.BoundParameters.Keys | ForEach-Object {
            $value = LeetABit.Build.Common\ConvertTo-ExpressionString $Invocation.BoundParameters[$_]
            Write-Verbose "  -$_ = $value"
        }
    }
}
