#requires -version 6

Set-StrictMode -Version 3

function Find-CommandArgumentInEnvironment {
    <#
    .SYNOPSIS
        Examines environmental variables for presence of a specified named parameter's value.
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
        $ParameterName
    )

    process {
        if (Test-Path "env:\$ParameterName") {
            Get-Content "env:\$ParameterName"
        }
    }
}
