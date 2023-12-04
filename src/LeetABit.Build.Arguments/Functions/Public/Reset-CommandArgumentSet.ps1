#requires -version 6

Set-StrictMode -Version 3

function Reset-CommandArgumentSet {
    <#
    .SYNOPSIS
        Removes all command arguments set in the module command.
    .DESCRIPTION
        Reset-CommandArgumentSet cmdlet clears all the module internal state that has been set via any of the previous calls to `Add-CommandArgument` and `Set-CommandArgumentSet` cmdlets.
    .EXAMPLE
        PS> Reset-CommandArgumentSet

        Removes all arguments stored in the `LeetABit.Build.Arguments` module.
    .LINK
        Add-CommandArgument
    .LINK
        Set-CommandArgumentSet
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = "Low")]

    param ()

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if ($PSCmdlet.ShouldProcess($LocalizedData.Resource_CurrentCommandArgumentSet,
                                    $LocalizedData.Operation_Clear)) {
            $script:ConfigurationJson = $Null
            $script:NamedArguments = @{}
            $script:PositionalArguments = @()
            $script:UnknownArguments.Clear()
        }
    }
}
