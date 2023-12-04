#requires -version 6

Set-StrictMode -Version 3

function Select-CommandArgumentSetCore {
    <#
    .SYNOPSIS
        Selects a collection of arguments that match specified command parameter set.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([IDictionary],[Object[]])]

    param (
        # Collection of the parameters for which a matching arguments shall be selected.
        [Parameter(HelpMessage = 'Provide collection of the parameters for which a matching arguments shall be selected.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [CommandParameterInfo[]]
        $Parameters,

        # Prefix for the parameters name that shall be used.
        [Parameter(HelpMessage = 'Provide prefix for the parameters name that shall be used.',
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $ExtensionName,

        # Dictionary of additional arguments that shall be used as a source of parameter's values.
        [Parameter(HelpMessage = "Provide dictionary of additional arguments that shall be used as a source of parameter's values.",
                   Position = 2,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [IDictionary]
        $AdditionalArguments
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $namedArguments = @{}
        $positionalArguments = @()
        $requiredMandatoryPositionalArguments = 0
        $requiredOptionalPositionalArguments = 0

        if ($Parameters) {
            foreach ($parameter in $Parameters) {
                $argument = $Null

                foreach ($suffix in @($parameter.Name) + $parameter.Aliases) {
                    $argument = Find-CommandArgument $parameter.Name $ExtensionName -IsSwitch:($parameter.ParameterType -eq [SwitchParameter]) -AdditionalArguments $AdditionalArguments
                    if ($null -ne $argument) {
                        break
                    }
                }

                if ($null -ne $argument) {
                    $namedArguments[$parameter.Name] = $argument
                    continue
                }

                if ($parameter.IsMandatory) {
                    if ($parameter.Position -ge 0) {
                        $requiredMandatoryPositionalArguments = [Math]::Max($requiredMandatoryPositionalArguments, ($parameter.Position + 1))
                    } else {
                        throw $LocalizedData.Exception_NamedParameterValueMissing_ParameterName -f $parameter.Name
                    }
                } else {
                    if ($parameter.Position -ge 0) {
                        $requiredOptionalPositionalArguments = [Math]::Max($requiredOptionalPositionalArguments, ($parameter.Position + 1))
                    }
                }
            }
        }

        $missingArguments = $requiredMandatoryPositionalArguments - $script:PositionalArguments.Length
        if ($missingArguments -gt 0) {
            throw $LocalizedData.Exception_PositionalParameterValueMissing_ParameterCount -f $missingArguments
        }

        $missingArguments = $requiredOptionalPositionalArguments - $script:PositionalArguments.Length

        if ($missingArguments -gt 0) {
            $positionalLimit = [Math]::Min($requiredMandatoryPositionalArguments, $script:PositionalArguments.Length)
            for ($i = 0; $i -lt $positionalLimit; ++$i) {
                $positionalArguments += $script:PositionalArguments[$i]
            }
        } else {
            $positionalLimit = [Math]::Min($requiredOptionalPositionalArguments, $script:PositionalArguments.Length)
            for ($i = 0; $i -lt $positionalLimit; ++$i) {
                $positionalArguments += $script:PositionalArguments[$i]
            }
        }

        $namedArguments
        Write-Output $positionalArguments -NoEnumerate
    }
}
