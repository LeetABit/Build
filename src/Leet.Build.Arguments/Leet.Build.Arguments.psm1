#requires -version 6

Set-StrictMode -Version 2

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'Continue'

$NamedArguments = @{}
[Collections.Generic.List[String]]$script:PositionalArguments = [Collections.Generic.List[String]]::new()
[Collections.Generic.List[String]]$script:UnknownArguments = [Collections.Generic.List[String]]::new()

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
    $script:NamedArguments.Clear()
    $script:NamedArguments.Add('RepositoryRoot', $RepositoryRoot)

    $script:PositionalArguments.Clear()

    $script:UnknownArguments.Clear()
    if ($Arguments) {
        $script:UnknownArguments.AddRange($Arguments)
    }

    Find-PositionalArguments
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
    if ($script:NamedArguments[$ArgumentName]) {
        $ArgumentFound.Value = $script:NamedArguments[$ArgumentName]
        return $True
    }

    for ($i = 0; $i -lt $script:UnknownArguments.Count; ++$i) {
        $unknownCandidate = $script:UnknownArguments[$i]
        $hasNaxtArgument = ($i + 1) -lt $script:UnknownArguments.Count
        if ($hasNaxtArgument) {
            $nextCandidate = $script:UnknownArguments[$i + 1]
        } elseif (-Not ($IsSwitch)) {
            $ArgumentFound.Value = $null
            return $False
        }

        $parameterName = Select-ParameterName $unknownCandidate
        if ($parameterName -eq $ArgumentName) {
            if ($IsSwitch) {
                if ($unknownCandidate.EndsWith(':')) {
                    if ($hasNaxtArgument) {
                        if (($nextCandidate -eq 'True') -or ($nextCandidate -eq 'False')) {
                            $script:NamedArguments[$ArgumentName] = [Switch][System.Boolean]$nextCandidate
                            $script:UnknownArguments.RemoveAt($i)
                            $script:UnknownArguments.RemoveAt($i)
                            if ($i -eq 0) { Find-PositionalArguments }                            
                            $ArgumentFound.Value = $script:NamedArguments[$ArgumentName]
                            return $True
                        }
                    }
                } else {
                    $script:NamedArguments[$ArgumentName] = [Switch]$True
                    $script:UnknownArguments.RemoveAt($i)
                    if ($i -eq 0) { Find-PositionalArguments }
                    $ArgumentFound.Value = $script:NamedArguments[$ArgumentName]
                    return $True
                }
            } else {
                $script:NamedArguments[$ArgumentName] = $nextCandidate
                $script:UnknownArguments.RemoveAt($i)
                $script:UnknownArguments.RemoveAt($i)
                if ($i -eq 0) { Find-PositionalArguments }
                $ArgumentFound.Value = $script:NamedArguments[$ArgumentName]
                return $True
            }
        }
    }

    return $False
}

<#
.SYNOPSIS
Finds positional arguments in list of not currently known arguments.
#>
function Find-PositionalArguments () {
    while ($script:UnknownArguments.Count -gt 0) {
        if (-Not (Test-ParameterName $script:UnknownArguments[0])) {
            $script:PositionalArguments += $script:UnknownArguments[0]
            $script:UnknownArguments.RemoveAt(0)
        } else { break }
    }
}

<#
.SYNOPSIS
Checks whether the specified argument represents a name of the parameter specifier.

.PARAMETER Argument
Argument which shall be checked.
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

Export-ModuleMember -Variable '*' -Alias '*' -Function '*' -Cmdlet '*'
