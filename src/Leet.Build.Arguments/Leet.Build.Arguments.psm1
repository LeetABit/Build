#requires -version 6

Set-StrictMode -Version 2

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'Continue'

$ConfigurationJson = $Null
$NamedArguments    = @{}

[Collections.Generic.List[String]]$script:PositionalArguments = [Collections.Generic.List[String]]::new()
[Collections.Generic.List[String]]$script:UnknownArguments    = [Collections.Generic.List[String]]::new()

<#
.SYNOPSIS
Sets an initial arguments for further processing.

.PARAMETER RepositoryRoot
Value of the -RepositoryRoot parameter.

.PARAMETER Arguments
Collection of other arguments passed.
#>
function Set-CommandArguments ( [String]   $RepositoryRoot ,
                                [String[]] $Arguments      ) {
    Initialize-ConfigurationFromFile $RepositoryRoot
    $script:NamedArguments.Clear()
    $script:NamedArguments.Add('RepositoryRoot', $RepositoryRoot)

    $script:PositionalArguments.Clear()

    $script:UnknownArguments.Clear()
    if ($Arguments) {
        $script:UnknownArguments.AddRange($Arguments)
    }

    Find-PositionalArguments

    $command = $Null
    if (-not (Find-NamedArgument 'Command' ([Ref]$command))) {
        if ($script:PositionalArguments.Count -gt 0) {
            $command = $script:PositionalArguments[0]
            $script:PositionalArguments.RemoveAt(0)
        } else {
            $command = Find-FirstPositionalArgument
        }

        if (-not $command) { $command = 'verify' }
        $script:NamedArguments.Add('Command', $command)
    }

    return $command
}

<#
.SYNOPSIS
Initializes a script configuration values from Leet.Build.json configuration file.

.PARAMETER RepositoryRoot
Value of the -RepositoryRoot parameter.
#>
function Initialize-ConfigurationFromFile ( [String] $RepositoryRoot ){
    $configFilePath = Join-Paths $RepositoryRoot ('build', 'Leet.Build.json')
    Write-Verbose "Initializing configuration using '$configFilePath' as fallback file."
    $script:ConfigurationJson = $Null

    if (Test-Path $configFilePath -PathType Leaf) {
        $configFileContent = Get-Content -Raw -Encoding UTF8 -Path $configFilePath
        $script:ConfigurationJson = ConvertFrom-Json $configFileContent
    }
}

<#
.SYNOPSIS
Gets a value for the specified script's parameter from the Leet.Build.json configuration file.

.PARAMETER ParameterName
Name of the script's parameter which value shall be obtained.

.PARAMETER DefaultValue
A default value for the script's parameter that shall be used if parameter's value is not present in the configuration file.

.NOTES
If default value is $Null then this function throws an exception if the parameter's value is not present if the configuration file.
#>
function Get-ConfigurationFileParameterValue ( [String] $ParameterName         ,
                                               [String] $DefaultValue  = $Null ) {
    $result = $DefaultValue
    if ($script:ConfigurationJson -and (Get-Member -Name $ParameterName -InputObject $script:ConfigurationJson)) {
        $result = $script:ConfigurationJson.$ParameterName
    }
    
    if ($result -eq $Null) {
        throw "Could not find '$ParameterName' member in Leet.Build.json configuration file."
    }

    return $result
}

<#
.SYNOPSIS
Gets a named and positional arguments that matches specified paramter names.

.PARAMETER ParameterNames
Name of the parameters for which values shall be found.

.PARAMETER NamedArguments
The variable that receives a hashtable with named arguments found.

.PARAMETER PositionalArguments
The variable that receives a collection with positional arguments found.
#>
function Select-Arguments(       [String]    $ParameterNames      ,
                           [Ref] [hashtable] $NamedArguments      ,
                           [Ref] [String[]]  $PositionalArguments ) {
    $NamedArguments.Value = @{}
    $PositionalArguments.Value = @()
    
    $ParameterNames.Keys | ForEach-Object {
        $argument = $null
        if (Find-NamedArgument $_ -IsSwitch:$ParameterNames[$_] ([Ref]$argument)) {
            $NamedArguments.Value[$_] = $argument
        }
    }

    if ($NamedArguments.Value.Count -lt $ParameterNames.Count) {
        $PositionalArguments.Value = $script:PositionalArguments + $script:UnknownArguments
    }
}

<#
.SYNOPSIS
Searches for a parameter for the specified named parameter.

.PARAMETER ParameterName
Name of the parameter for which the argument has to be found.

.PARAMETER IsSwitch
Determines whether the parametr is a switch parameter.

.PARAMETER ArgumentFound
A variable that receives a value of the named parameter found.
#>
function Find-NamedArgument (       [String] $ParameterName ,
                                    [Switch] $IsSwitch      ,
                              [Ref] [Object] $ArgumentFound ) {
    if ($script:NamedArguments[$ParameterName]) {
        $ArgumentFound.Value = $script:NamedArguments[$ParameterName]
        return $True
    }

    for ($i = 0; $i -lt $script:UnknownArguments.Count; ++$i) {
        $unknownCandidate = $script:UnknownArguments[$i]
        $hasNaxtArgument = ($i + 1) -lt $script:UnknownArguments.Count
        if ($hasNaxtArgument) {
            $nextCandidate = $script:UnknownArguments[$i + 1]
        } elseif (-Not ($IsSwitch)) {
            break
        }

        $parameterName = Select-ParameterName $unknownCandidate
        if ($parameterName -eq $ParameterName) {
            if ($IsSwitch) {
                if ($unknownCandidate.EndsWith(':')) {
                    if ($hasNaxtArgument) {
                        if (($nextCandidate -eq 'True') -or ($nextCandidate -eq 'False')) {
                            $script:NamedArguments[$ParameterName] = [Switch][System.Boolean]$nextCandidate
                            $script:UnknownArguments.RemoveAt($i)
                            $script:UnknownArguments.RemoveAt($i)
                            if ($i -eq 0) { Find-PositionalArguments }
                            $ArgumentFound.Value = $script:NamedArguments[$ParameterName]
                            return $True
                        }
                    }
                } else {
                    $script:NamedArguments[$ParameterName] = [Switch]$True
                    $script:UnknownArguments.RemoveAt($i)
                    if ($i -eq 0) { Find-PositionalArguments }
                    $ArgumentFound.Value = $script:NamedArguments[$ParameterName]
                    return $True
                }
            } else {
                $script:NamedArguments[$ParameterName] = $nextCandidate
                $script:UnknownArguments.RemoveAt($i)
                $script:UnknownArguments.RemoveAt($i)
                if ($i -eq 0) { Find-PositionalArguments }
                $ArgumentFound.Value = $script:NamedArguments[$ParameterName]
                return $True
            }
        }
    }

    $defaultValue = [guid]::NewGuid()
    $ArgumentFound.Value = Get-ConfigurationFileParameterValue $ParameterName $defaultValue
    return $ArgumentFound.Value -ne $defaultValue
}

<#
.SYNOPSIS
Finds positional arguments in list of not currently known arguments.
#>
function Find-PositionalArguments {
    while ($script:UnknownArguments.Count -gt 0) {
        if (-Not (Test-ParameterName $script:UnknownArguments[0])) {
            $script:PositionalArguments += $script:UnknownArguments[0]
            $script:UnknownArguments.RemoveAt(0)
        } else { break }
    }
}

<#
.SYNOPSIS
Finds first positional arguments in list of not currently known arguments skipping candidates for named arguments.
#>
function Find-FirstPositionalArgument {
    $index = 0

    while ($script:UnknownArguments.Count -gt $index) {
        if (-Not (Test-ParameterName $script:UnknownArguments[$index])) {
            $result = $script:UnknownArguments[$index]
            $script:UnknownArguments.RemoveAt($index)
            return $result
        } else {
            $index += 2
        }
    }

    return $Null
}

<#
.SYNOPSIS
Checks whether the specified argument represents a name of the parameter specifier.

.PARAMETER Argument
Argument which shall be checked.

.PARAMETER ParametrName
A variable that gets a value of the parameter's name found.
#>
function Test-ParameterName (       [String] $Argument     ,
                              [Ref] [String] $ParametrName ) {
    $firstParameterChar = '\p{Lu}|\p{Ll}|\p{Lt}|\p{Lm}|\p{Lo}|_|\?'
    $parameterChar = '[^\{\}\(\)\;\,\|\&\.\[\:\s\n]'

    if ($Argument -match "^-(($firstParameterChar)($parameterChar)+)\:?$") {
        $ParametrName = $matches[1]
        return $True
    }

    $ParametrName = $null
    return $False
}

<#
.SYNOPSIS
Selects arguments for the specified parameters.

.PARAMETER Parameters
Dictionary that contains name of the parameters mapped to a value which determines whether the parameter is a switch.

.PARAMETER NamedArguments
Variable which gets a dictionary of parameter names mapped to its argument's values.

.PARAMETER PositionalArguments
Variable which gets a collection of argument's values for parameters which names were not specfied.
#>
function Select-Arguments([Hashtable] $Parameters, [Ref][Hashtable] $NamedArguments, [Ref][String[]] $PositionalArguments) {
    $NamedArguments.Value = @{}
    $PositionalArguments.Value = @()
    
    $Parameters.Keys | ForEach-Object {
        $argument = $null
        if (Find-NamedArgument $_ -IsSwitch:$Parameters[$_] ([Ref]$argument)) {
            $NamedArguments.Value[$_] = $argument
        }
    }

    if ($NamedArguments.Value.Count -lt $Parameters.Count) {
        $PositionalArguments.Value = $script:PositionalArguments + $script:UnknownArguments
    }
}

Export-ModuleMember -Variable '*' -Alias '*' -Function '*' -Cmdlet '*'
