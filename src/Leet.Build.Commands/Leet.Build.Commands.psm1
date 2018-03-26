#requires -version 6

Set-StrictMode -Version 2

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'Continue'

<#
.SYNOPSIS
Invokes Leet.Build command defined by the passed arguments.

.PARAMETER CommandName
Name of the command to invoke.

.PARAMETER IncludeExtensions
Specified whether the implementation in extension modules shall also be considered.

.PARAMETER ThrowOnNoHandler
Throws an exception if no handler function has been found for the specified command.
#>
function Invoke-Command ( [String] $CommandName       ,
                          [Switch] $IncludeExtensions ,
                          [Switch] $ThrowOnNoHandler  ) {
    $found = $false
    foreach ($function in Get-CommandFunctions -CommandName $CommandName -IncludeExtensions:$IncludeExtensions) {
        $found = $true
        if (Invoke-CommandFunction $function) {
            break
        }
    }
                      
    if ($ThrowOnNoHandler) {
        if (-not $found) {
            throw "Could not find handler for '$CommandName' command."
        }
    } else {
        return $found
    }
}

<#
.SYNOPSIS
Gets Leet.Build modules loaded with optional project's extension module.

.PARAMETER IncludeExtension
Specified whether the project extension module shall be included in result.
#>
function Get-LeetBuildModules ( [Switch] $IncludeExtension ) {
    if ($IncludeExtension) {
        return Get-Module | Sort-Object {
            if ( $_.Name -eq 'Leet.Build.Project' ) { 0 } else { 1 }
        }
    } else {
        return Get-Module | Where-Object {
            $_.Name -ne 'Leet.Build.Project'
        }
    }
}

<#
.SYNOPSIS
Gets a collection of functions of the specified name defined in all imported Leet.Build modules.

.PARAMETER CommandName
Name of the command to invoke.

.PARAMETER IncludeExtensions
Specified whether the implementation in extension modules shall also be considered.
#>
function Get-CommandFunctions( [String] $CommandName       ,
                               [Switch] $IncludeExtensions ) {
    $result = @()

    foreach ($module in Get-LeetBuildModules -IncludeExtensions) {
        $functions = Get-CommandFunctionsFromModule $CommandName $module
        if ($functions) {
            $result += $functions
        }
    }
    
    return $result
}

<#
.SYNOPSIS
Gets a function that implements a specified command.

.PARAMETER CommandName
Name of the command which implementation shall be obtained.

.PARAMETER Module
Module which shall be searched for the command's implementation.
#>
function Get-CommandFunctionsFromModule( [String]       $CommandName  ,
                                         [PSModuleInfo] $Module       ) {
    $functionNamePattern = if ($CommandName) { $CommandName } else { '.*' }
    $functionNamePattern = "^Invoke-OnLeetBuild$($functionNamePattern)Command$"
    $result = @()
    
    foreach ($commandInfo in $Module.ExportedCommands.Values) {
		if ($commandInfo.Name -match $functionNamePattern) {
            $result += $commandInfo
        }
    }

    return $result
}

<#
.SYNOPSIS
Invokes an implementation of the Leet.Build command located in the specified module.

.PARAMETER Command
Command function to be invoked.
#>
function Invoke-CommandFunction ( [System.Management.Automation.CommandInfo] $Command ) {
    $NamedArguments = @{}
    $PositionalArguments = @()
    $Parameters = Get-FunctionParameters $Command
    Leet.Build.Arguments\Select-CommandArguments $Parameters ([Ref]$NamedArguments) ([Ref]$PositionalArguments)
    return Invoke-Expression "& $($Command.Module.Name)\$($Command.Name) @NamedArguments @PositionalArguments"
}

<#
.SYNOPSIS
Gets a parameters of the specified command implementation.

.PARAMETER Command
Implementation of the command which parameters shall be obtained.
#>
function Get-FunctionParameters([System.Management.Automation.CommandInfo] $Command){
    $result = @{}
    $helpStructure = Get-Help "$($Command.Module.Name)\$($Command.Name)" -Full

    if ($helpStructure.parameters.PSobject.Properties.Name -contains 'parameter') {
        $helpStructure.parameters.parameter | Foreach-Object {
            $result[$_.name] = $_.type.name -eq "switch"
        }
    }

    return $result
}

Export-ModuleMember -Variable '*' -Alias '*' -Function '*' -Cmdlet '*'
