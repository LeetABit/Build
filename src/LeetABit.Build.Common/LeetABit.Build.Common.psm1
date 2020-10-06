#requires -version 6
using namespace System.Management.Automation
using namespace System.Collections

Set-StrictMode -Version 2
Import-LocalizedData -BindingVariable LocalizedData -FileName LeetABit.Build.Common.Resources.psd1


##################################################################################################################
# Public Commands
##################################################################################################################


function Convert-DictionaryToPSObject {
    <#
    .SYNOPSIS
        Convets a hashtable to a PSObject using keys as property names with associated values.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String])]

    param (
        # A hashtable with desired object's properties.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [IDictionary]
        $Properties,

        # An optional array of type names to be added to the custom object.
        [Parameter(Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $TypeName
    )

    begin {
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $result = New-Object PSObject -Property $Properties
        if ($TypeName) {
            foreach ($currentTypeName in $TypeName) {
                $result.PSObject.TypeNames.Add($currentTypeName)
            }
        }

        $result
    }
}


function Format-String {
    <#
    .SYNOPSIS
        Formats the specified object as a plain string.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Object to format.
        [Parameter(HelpMessage = 'Provide an object to format.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [AllowNull()]
        [Object]
        $Obj
    )

    process {
        Format-StringWithIndentation $Obj 0
    }
}


function Import-CallerPreference {
    <#
    .SYNOPSIS
        Fetches "Preference" variable values from the caller's scope.
    .DESCRIPTION
        Script module functions do not automatically inherit their caller's variables, but they can be
        obtained through the $PSCmdlet variable in Advanced Functions. This function is a helper function
        for any script module Advanced Function; by passing in the values of $PSCmdlet and
        $ExecutionContext.SessionState, Import-CallerPreference will set the caller's preference variables locally.
    .EXAMPLE
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        Imports the default PowerShell preference variables from the caller into the local scope.
    .INPUTS
        None. This function does not take any input.
    .OUTPUTS
        None. This function does not produce pipeline output.
    .LINK
        about_Preference_Variables
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # The $PSCmdlet object from a script module Advanced Function.
        [Parameter(HelpMessage = 'Provide an instance of the $PSCmdlet object.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [PSCmdlet]
        $Cmdlet,

        # The $ExecutionContext.SessionState object from a script module Advanced Function.
        # This is how the Import-CallerPreference function sets variables in its callers' scope,
        # even if that caller is in a different script module.
        [Parameter(HelpMessage = 'Provide an instance of the $ExecutionContext.SessionState object.',
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [SessionState]
        $SessionState
    )

    begin {
        $preferenceVariablesMap = @{
            'ErrorView' = $null
            'FormatEnumerationLimit' = $null
            'InformationPreference' = $null
            'LogCommandHealthEvent' = $null
            'LogCommandLifecycleEvent' = $null
            'LogEngineHealthEvent' = $null
            'LogEngineLifecycleEvent' = $null
            'LogProviderHealthEvent' = $null
            'LogProviderLifecycleEvent' = $null
            'MaximumAliasCount' = $null
            'MaximumDriveCount' = $null
            'MaximumErrorCount' = $null
            'MaximumFunctionCount' = $null
            'MaximumHistoryCount' = $null
            'MaximumVariableCount' = $null
            'OFS' = $null
            'OutputEncoding' = $null
            'ProgressPreference' = $null
            'PSDefaultParameterValues' = $null
            'PSEmailServer' = $null
            'PSModuleAutoLoadingPreference' = $null
            'PSSessionApplicationName' = $null
            'PSSessionConfigurationName' = $null
            'PSSessionOption' = $null

            'ConfirmPreference' = 'Confirm'
            'DebugPreference' = 'Debug'
            'ErrorActionPreference' = 'ErrorAction'
            'VerbosePreference' = 'Verbose'
            'WarningPreference' = 'WarningAction'
            'WhatIfPreference' = 'WhatIf'
        }
    }

    process {
        foreach ($variableName in $preferenceVariablesMap.Keys) {
            $parameterName = $preferenceVariablesMap[$variableName]
            if (-not $parameterName `
                -or `
                -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($parameterName)) {
                $variable = $Cmdlet.SessionState.PSVariable.Get($variableName)

                if ($variable)
                {
                    if ($SessionState -eq $ExecutionContext.SessionState)
                    {
                        Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                    }
                    else
                    {
                        $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                    }
                }
            }
        }
    }
}


##################################################################################################################
# Private Commands
##################################################################################################################


function Format-StringWithIndentation {
    <#
    .SYNOPSIS
        Formats the specified object as a plain string.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Object to format.
        [Parameter(HelpMessage = 'Provide an object to format.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [AllowNull()]
        [Object]
        $Obj,

        # Indentation level.
        [Parameter(HelpMessage = 'Provide an indentation level.',
                   Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [Int32]
        $IndentationLevel
    )

    process {
        $prefix = "  " * $IndentationLevel

        if ($Null -eq $Obj) {
            '$Null'
        }
        elseif ($Obj -is [String]) {
            "'$Obj'"
        }
        elseif ($Obj -is [SwitchParameter] -or $Obj -is [Boolean]) {
            "`$$Obj"
        }
        elseif ($Obj -is [IDictionary]) {
            $result = "@{"
            $Obj.Keys | ForEach-Object {
                $value = Format-StringWithIndentation $Obj[$_] ($IndentationLevel + 1)
                $result += [Environment]::NewLine + "$prefix  '$_' = $value; "
            }

            $result = $result.Substring(0, $result.Length - 2)
            $result += [Environment]::NewLine + "$prefix}"
            $result
        }
        elseif ($Obj -is [PSCustomObject]) {
            $result = ""

            if ($Obj.PSObject.TypeNames.Count -gt 0) {
                $result += "<# "
                $Obj.PSObject.TypeNames | ForEach-Object {
                    if ($_ -ne "Selected.System.Management.Automation.PSCustomObject" -and
                        $_ -ne "System.Management.Automation.PSCustomObject" -and
                        $_ -ne "System.Object") {
                        $result += "[$_], "
                    }
                }

                $result = $result.Substring(0, $result.Length - 2)
                $result += " #> "
            }

            $result += "@{"
            Get-Member -InputObject $Obj -MemberType NoteProperty | ForEach-Object {
                $value = $Obj | Select-Object -ExpandProperty $_.Name
                $value = Format-StringWithIndentation $value ($IndentationLevel + 1)
                $result += [Environment]::NewLine + "$prefix  '$($_.Name)' = $value; "
            }

            $result = $result.Substring(0, $result.Length - 2)
            $result += [Environment]::NewLine + "$prefix}"
            $result
        }
        elseif ($Obj -is [IEnumerable]) {
            $result = "("
            $Obj | ForEach-Object {
                $value = Format-StringWithIndentation $_ ($IndentationLevel + 1)
                $result += [Environment]::NewLine + "$prefix  $value, "
            }

            $result = $result.Substring(0, $result.Length - 2)
            $result += [Environment]::NewLine + "$prefix)"
            $result
        }
        else {
            [String]$Obj
        }
    }
}


##################################################################################################################
# Classes
##################################################################################################################


<#
    Validates specified argument as a path to a container.
#>
class ValidateContainerPathAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        $path = [String]$arguments

        if ([String]::IsNullOrWhiteSpace($path)) {
            throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
        }

        Join-Path $path '.'

        if (-not (Test-Path -Path $path -PathType Container)) {
            throw [System.ArgumentException]::new("Argument '$path' is not a valid path to an existing container.")
        }
    }
}


<#
    Validates specified argument as a path to a leaf.
#>
class ValidateLeafPathAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        $path = [String]$arguments

        if ([String]::IsNullOrWhiteSpace($path)) {
            throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
        }

        Join-Path $path '.'

        if (-not (Test-Path -Path $path -PathType Leaf)) {
            throw [System.ArgumentException]::new('Argument is not a valid path to an existing leaf.')
        }
    }
}


<#
    Validates specified argument as a string of consecutive alphanumeric characters.
#>
class ValidateIdentifierAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        $identifier = [String]$arguments

        if ([String]::IsNullOrWhiteSpace($identifier)) {
            throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
        }

        if ($identifier -notmatch '^[a-z_][a-z0-9_]*$') {
            throw [System.ArgumentException]::new('Specified string was not a correct identifier.')
        }
    }
}


<#
    Validates specified argument as an empty string or string of consecutive alphanumeric characters.
#>
class ValidateIdentifierOrEmptyAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        $identifier = [String]$arguments

        if ([String]::IsNullOrEmpty($identifier)) {
            return
        }

        if ([String]::IsNullOrWhiteSpace($identifier)) {
            throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
        }

        if ($identifier -notmatch '^[a-z_][a-z0-9_]*$') {
            throw [System.ArgumentException]::new('Specified string was not a correct identifier.')
        }
    }
}


<#
    Validates specified argument as a path to a leaf or non-existant entry.
#>
class ValidateNonContainerPathAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        $path = [String]$arguments

        if ([String]::IsNullOrWhiteSpace($path)) {
            throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
        }

        Join-Path $path '.'

        if (Test-Path -Path $path -PathType Container) {
            throw [System.ArgumentException]::new('Argument cannot be a path to an existing container.')
        }
    }
}


<#
    Validates specified argument as a path to a container or non-existant entry.
#>
class ValidateNonLeafPathAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        $path = [String]$arguments

        if ([String]::IsNullOrWhiteSpace($path)) {
            throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
        }

        Join-Path $path '.'

        if (Test-Path -Path $path -PathType Leaf) {
            throw [System.ArgumentException]::new('Argument cannot be a path to an existing leaf.')
        }
    }
}


<#
    Validates specified argument as a PowerShell path.
#>
class ValidatePathAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        $path = [String]$arguments

        if ([String]::IsNullOrWhiteSpace($path)) {
            throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
        }

        Join-Path $path '.'
    }
}


Export-ModuleMember -Function '*' -Variable '*' -Alias '*' -Cmdlet '*'
