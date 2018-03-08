#requires -version 6

Set-StrictMode -Version 2

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'Continue'

<#
.SYNOPSIS
Invokes Leet.Build command defined by the passed arguments.

.PARAMETER RepositoryRoot
Value of the -RepositoryRoot parameter.

.PARAMETER Arguments
Collection of other arguments passed.
#>
function Invoke-Command ( [String]   $RepositoryRoot ,
                          [String[]] $Arguments      ) {
    $command = Leet.Build.Arguments\Set-CommandArguments $RepositoryRoot $Arguments

    Invoke-CommandFunction "Invoke-Before$($command)Command" -IncludeExtensions
    Invoke-CommandFunction "Invoke-On$($command)Command" -IncludeExtensions
}

<#
.SYNOPSIS
Invokes Leet.Build command specified by its name.

.PARAMETER CommandName
Name of the command which implementation shall be invoked.

.PARAMETER IncludeExtensions
Specified whether the implementation in extension modules shall also be considered.
#>
function Invoke-CommandFunction ( [String] $CommandName        ,
                                  [Switch] $IncludeExtensions  ) {
    foreach ($module in Get-CommandModules -IncludeExtensions:$IncludeExtensions) {
        if (Invoke-CommandFunctionFromModule $CommandName $module) {
            continue
        }
    }
}

<#
.SYNOPSIS
Gets Leet.Build modules loaded with optional project's extension modules.

.PARAMETER IncludeExtensions
Specified whether the implementation in extension modules shall also be considered.
#>
function Get-CommandModules ( [Switch] $IncludeExtensions ) {
    $extensionModules = Leet.Build.Extensions\Get-ExtensionModules
    $nonExtensionModules = (Leet.Build.Modules\Get-ImportedModules) | Where-Object { $extensionModules -notcontains $_ }
    $modules = @()
    if ($IncludeExtensions) { $modules += $extensionModules }
    $modules += $nonExtensionModules
    return $modules
}

<#
.SYNOPSIS
Invokes an implementation of the Leet.Build command located in the specified module.

.PARAMETER CommandName
Name of the command which implementation shall be invoked.

.PARAMETER Module
Module which shall be searched for the command's implementation.
#>
function Invoke-CommandFunctionFromModule ([String] $CommandName, [PSModuleInfo] $Module) {
    $function = Get-CommandFunction $CommandName $Module
    if ($function) {
        $NamedArguments = @{}
        $PositionalArguments = @()
        $Parameters = Get-FunctionParameters $function
        Leet.Build.Arguments\Select-ArgumentsMatchingCommand $Parameters ([Ref]$NamedArguments) ([Ref]$PositionalArguments)
        return Invoke-Expression "& `$Module $function @NamedArguments @PositionalArguments"
    }
}

<#
.SYNOPSIS
Gets a function that implements a specified command.

.PARAMETER CommandName
Name of the command which implementation shall be obtained.

.PARAMETER Module
Module which shall be searched for the command's implementation.
#>
function Get-CommandFunction([String] $CommandName, [PSModuleInfo] $Module){
    foreach ($commandInfo in $Module.ExportedCommands.Values) {
		if ($commandInfo.Name -eq $CommandName) {
                return $commandInfo
        }
    }

    return $Null
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
