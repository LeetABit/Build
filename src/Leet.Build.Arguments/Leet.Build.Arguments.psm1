#requires -version 6
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation
using module Leet.Build.Common

Set-StrictMode -Version 2
Import-LocalizedData -BindingVariable LocalizedData -FileName Leet.Build.Arguments.Resources.psd1

$ConfigurationJson   = $Null
$NamedArguments      = @{}
$PositionalArguments = @()
[ArrayList]$UnknownArguments = @()

$AllParameterSets = '__AllParameterSets'

##################################################################################################################
# Public Commands
##################################################################################################################


function Find-CommandArgument {
    <#
    .SYNOPSIS
    Locates an argument for a specified named parameter.
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

        # Name of the build extension in which the command is defined.
        [Parameter(Position=1,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [String]
        $ExtensionName,

        # Default value that shall be used when no argument with the specified name is found.
        [Parameter(Position=2,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [Object]
        $DefaultValue,

        # Indicates whether the argument shall be threated as a value for [Switch] parameter.
        [Parameter(Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [Switch]
        $IsSwitch,

        # A dictionary that holds an additional arguments to be used as a parameter's value source.
        [Parameter(Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$False)]
        [IDictionary]
        $AdditionalArguments
    )

    begin {
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $parameterNames = @()
        if ($ExtensionName) {
            $parameterNames += "$($ExtensionName.Replace('.', [String]::Empty))`_$ParameterName"
        }

        $parameterNames += "LeetBuild_$ParameterName"
        $parameterNames += $ParameterName

        foreach ($parameterNameToFind in $parameterNames) {
            $result = Find-CommandArgumentInDictionary $parameterNameToFind -Dictionary $AdditionalArguments
            if ($result) {
                Convert-ArgumentValue $result -IsSwitch:$IsSwitch
                return
            }

            $result = Find-CommandArgumentInCommandLine $parameterNameToFind -IsSwitch:$IsSwitch
            if ($result) {
                Convert-ArgumentValue $result -IsSwitch:$IsSwitch
                return
            }

            $result = Find-CommandArgumentInConfiguration $parameterNameToFind
            if ($result) {
                Convert-ArgumentString $result -IsSwitch:$IsSwitch
                return
            }

            $result = Find-CommandArgumentInEnvironment $parameterNameToFind
            if ($result) {
                Convert-ArgumentString $result -IsSwitch:$IsSwitch
                return
            }
        }

        if ($DefaultValue) {
            $DefaultValue
        }
    }
}


function Reset-CommandArgumentSet {
    <#
    .SYNOPSIS
    Removes all command arguments set by Set-CommandArgumentSet command.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = "Low")]

    param ()

    begin {
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if ($pscmdlet.ShouldProcess($LocalizedData.Resource_CurrentCommandArgumentSet,
                                    $LocalizedData.Operation_Clear)) {
            $script:ConfigurationJson = $Null
            $script:NamedArguments = @{}
            $script:PositionalArguments = @()
            $script:UnknownArguments.Clear()
        }
    }
}


function Select-CommandArgumentSet {
    <#
    .SYNOPSIS
    Selects a collection of arguments that match specified command parameters.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   DefaultParameterSetName = "Command")]
    [OutputType([IDictionary],[Object[]])]

    param (
        # Command for which a matching arguments shall be seleted.
        [Parameter(HelpMessage = 'Provide command info object for which arguments shall be selected.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = "Command")]
        [System.Management.Automation.CommandInfo]
        $Command,

        # Script block for which a matching arguments shall be seleted.
        [Parameter(HelpMessage = 'Provide script block object for which arguments shall be selected.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = "ScriptBlock")]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        # Collection of the parameter sets for which a matching arguments shall be seleted.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = "Manual")]
        [CommandParameterSetInfo[]]
        $ParameterSets,

        # Name of the build extension for which the arguments shall be selected.
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

        # Dictionary of additional arguments that shall be used as a source of parameter's values.
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
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Command') {
            $ParameterSets = $Command.ParameterSets

            if (-not $ExtensionName -and $Command.ModuleName) {
                $ExtensionName = $Command.ModuleName
            }
        } elseif ($PSCmdlet.ParameterSetName -eq 'ScriptBlock') {
            if ($ScriptBlock.Ast.ParamBlock) {
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

        if (-not $found) {
            throw $LocalizedData.Error_SelectCommandArgumentSet_Reason -f
                ($LocalizedData.Reason_NoMatchingParameterSetFound_NewLine_Errors -f [Environment]::NewLine, ($errors -join [Environment]::NewLine))
        }

        $namedArguments
        Write-Output -NoEnumerate $positionalArguments
    }
}


function Set-CommandArgument {
    <#
    .SYNOPSIS
    Sets a value for the specified parameter.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Name of the parameter which value shall be updated.
        [Parameter(HelpMessage = 'Provide name of the parameter which value shall be updated',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [ValidateIdentifierAttribute()]
        [String]
        $ParameterName,

        # A new value for the parameter.
        [Parameter(HelpMessage = 'Provide a new value for the parameter.',
                   Position=1,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [String]
        $ParameterValue,

        # Indicates that this cmdlet overwrites value already set to the parameter.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [Switch]
        $Force)

    begin {
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if ($script:NamedArguments.ContainsKey($ParameterName)) {
            if (-not $Force) {
                throw $LocalizedData.Error_SetCommandArgument_Reason -f
                    ($LocalizedData.Reason_ArgumentAlreadySet_ParameterName -f $ParameterName)
            }
        }

        $script:NamedArguments[$ParameterName] = $ParameterValue
    }
}


function Set-CommandArgumentSet {
    <#
    .SYNOPSIS
    Sets a collection of arguments that shall be used for command execution.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = 'Low')]

    param (
        # Location of the repository on which te command will be executed.
        [Parameter(HelpMessage = 'Provide path to the root folder of the repository for which the command will be executed.',
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [ValidateContainerPathAttribute()]
        [String]
        $RepositoryRoot,

        # Dictionary of buildstrapper parmaters (including dynamic ones) that have been successfully bound.
        [Parameter(Position=1,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [IDictionary]
        $NamedArguments,

        # Collection of other arguments passed.
        [Parameter(Position=2,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [String[]]
        $UnknownArguments)

    begin {
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if ($PSCmdlet.ShouldProcess($LocalizedData.Resource_CurrentCommandArgumentSet,
                                    $LocalizedData.Operation_Overwrite)) {
            Initialize-ConfigurationFromFile $RepositoryRoot
            $script:NamedArguments = @{}
            $script:PositionalArguments = @()
            $script:UnknownArguments.Clear()

            $NamedArguments.Keys | ForEach-Object {
                $script:NamedArguments.Add($_, $NamedArguments[$_])
            }

            if ($UnknownArguments) {
                $script:UnknownArguments.AddRange($UnknownArguments)
                Pop-PositionalArguments
            }
        }
    }
}


##################################################################################################################
# Private Commands
##################################################################################################################


function Convert-ArgumentString {
    <#
    .SYNOPSIS
    Conditionaly converts a specified string argument to a [Switch] type.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([Object[]])]

    param (
        # Argument string to convert.
        [Parameter(HelpMessage = 'Provide argument string value.',
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [String[]]
        $Value,

        # Indicates whether the argument shall be threated as a value for [Switch] parameter.
        [Parameter(Position=1,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [Switch]
        $IsSwitch)

    process {
        $Value | ForEach-Object {
            if ($IsSwitch) {
                if ($_ -eq '0' -or
                $_ -eq 'False') {
                    [Switch]$False
                } else {
                    [Switch]$True
                }
            }
            else {
                $_
            }
        }
    }
}


function Convert-ArgumentValue {
    <#
    .SYNOPSIS
    Conditionaly converts a specified argument to a [Switch] type.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([Object[]])]

    param (
        # Argument to convert.
        [Parameter(HelpMessage = 'Provide argument value.',
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [Object[]]
        $Value,

        # Indicates whether the argument shall be threated as a value for [Switch] parameter.
        [Parameter(Position=1,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [Switch]
        $IsSwitch)

    process {
        $Value | ForEach-Object {
            if ($IsSwitch) {
                if ($_) {
                    [Switch][Boolean]$_
                } else {
                    [Switch]$True
                }
            }
            else {
                $_
            }
        }
    }
}


function Find-CommandArgumentInCommandLine {
    <#
    .SYNOPSIS
    Examines command line arguments for presence of a specified named parameter's value.
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
        $IsSwitch)

    process {
        foreach ($dictionaryParameterName in $script:NamedArguments.Keys) {
            if ($dictionaryParameterName -ne $ParameterName) {
                continue
            }

            $script:NamedArguments[$ParameterName]
            return
        }

        Find-CommandArgumentInUnknownArguments $ParameterName $IsSwitch
    }
}


function Find-CommandArgumentInConfiguration {
    <#
    .SYNOPSIS
    Examines JSON configuration file for presence of a specified named parameter's value.
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
        $ParameterName)

    process {
        if ($script:ConfigurationJson -and (Get-Member -Name $ParameterName -InputObject $script:ConfigurationJson)) {
            $script:ConfigurationJson.$ParameterName
            return
        }
    }
}


function Find-CommandArgumentInDictionary {
    <#
    .SYNOPSIS
    Examines s[ecified arguments dictionary for presence of a specified named parameter's value.
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

        # A dictionary that holds an arguments to be used as a parameter's value source.
        [Parameter(Position=2,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$False)]
        [IDictionary]
        $Dictionary)

    process {
        if ($Dictionary) {
            foreach ($dictionaryParameterName in $Dictionary.Keys) {
                if ($dictionaryParameterName -ne $ParameterName) {
                    continue
                }

                $Dictionary[$dictionaryParameterName]
                break
            }
        }
    }
}


function Find-CommandArgumentInEnvironment {
    <#
    .SYNOPSIS
    Examines envirnmental variables for presence of a specified named parameter's value.
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
        $localParameterName = $ParameterName
        if ($localParameterName -notmatch '^Leet[a-zA-Z]*_[a-zA-Z]+[a-zA-Z0-9_]*$') {
            $localParameterName = "Leet_$localParameterName"
        }

        if (Test-Path "env:\$localParameterName") {
            Get-Content "env:\$localParameterName"
        }
    }
}


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
            $hasNaxtArgument = ($i + 1) -lt $script:UnknownArguments.Count
            if ($hasNaxtArgument) {
                $nextCandidate = $script:UnknownArguments[$i + 1]
            } elseif (-Not ($IsSwitch)) {
                break
            }

            $candidateParameterName = Select-ParameterName $unknownCandidate
            if ($candidateParameterName -eq $ParameterName) {
                $simpleSwitch = $False

                if ($IsSwitch) {
                    if ($unknownCandidate.EndsWith(':')) {
                        if ($hasNaxtArgument) {
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


function Pop-PositionalArguments {
    <#
    .SYNOPSIS
    Locates a positional argument in a head of the collection of arguments which kind has not yet been determined.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param ()

    process {
        while ($script:UnknownArguments.Count -gt 0) {
            if (-Not (Test-ParameterName $script:UnknownArguments[0])) {
                $script:PositionalArguments += $script:UnknownArguments[0]
                $script:UnknownArguments.RemoveAt(0)
            }
            else {
                break
            }
        }
    }
}


function Initialize-ConfigurationFromFile {
    <#
    .SYNOPSIS
    Initializes a script configuration values from Leet.Build.json configuration file.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Location of the repository for which te configuration file shall be located.
        [Parameter(HelpMessage = "Provide path to the repository root directory.",
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [ValidateContainerPathAttribute()]
        [String]
        $RepositoryRoot
    )

    process {
        $script:ConfigurationJson = @{}
        Get-ChildItem -Path $RepositoryRoot -Filter 'Leet.Build.json' -Recurse | Foreach-Object {
            $configFilePath = $_.FullName
            Write-Verbose ($LocalizedData.Message_InitializingConfigurationFromFile_FilePath -f $configFilePath)

            if (Test-Path $configFilePath -PathType Leaf) {
                try {
                    $configFileContent = Get-Content -Raw -Encoding UTF8 -Path $configFilePath
                    $configJson = ConvertFrom-Json $configFileContent
                    $configJson.psobject.Properties | ForEach-Object {
                        $script:ConfigurationJson | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value -Force
                    }
                }
                catch {
                    throw [System.IO.FileFormatException]::new([Uri]::new($configFilePath), $LocalizedData.Exception_IncorrectJsonFileFormat, $_)
                }
            }
        }
    }
}


function Select-CommandArgumentSetCore {
    <#
    .SYNOPSIS
    Selects a collection of arguments that match specified command parameter set.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([IDictionary],[Object[]])]

    param (
        # Collection of the parameters for which a matching arguments shall be seleted.
        [Parameter(HelpMessage = 'Provide collection of the parameters for which a matching arguments shall be seleted.',
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
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
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


function Select-ParameterName {
    <#
    .SYNOPSIS
    Obtains a parameter name from the specified argument if it matches an parameter name pattern.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String])]

    param (
        # Argument to examine.
        [Parameter(HelpMessage = "Provide value of the command's argument.",
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [String]
        $Argument)

    process {
        $firstParameterChar = '\p{Lu}|\p{Ll}|\p{Lt}|\p{Lm}|\p{Lo}|_|\?'
        $parameterChar = '[^\{\}\(\)\;\,\|\&\.\[\:\s\n]'

        if ($Argument -match "^-(($firstParameterChar)($parameterChar)*)\:?$") {
            $matches[1]
        }
    }
}


function Test-ParameterName {
    <#
    .SYNOPSIS
    Checks whether the specified argument represents a name of the parameter specifier.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([System.Boolean])]

    param (
        # Argument which shall be checked.
        [Parameter(HelpMessage = "Provide value of the command's argument.",
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [String]
        $Argument)

    process {
        $firstParameterChar = '\p{Lu}|\p{Ll}|\p{Lt}|\p{Lm}|\p{Lo}|_|\?'
        $parameterChar = '[^\{\}\(\)\;\,\|\&\.\[\:\s\n]'

        $Argument -match "^-(($firstParameterChar)($parameterChar)*)\:?$"
    }
}


Export-ModuleMember -Function '*' -Variable '*' -Alias '*' -Cmdlet '*'
