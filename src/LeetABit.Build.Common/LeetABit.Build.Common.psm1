#requires -version 6
using namespace System.Management.Automation
using namespace System.Collections
using namespace System.Diagnostics.CodeAnalysis
using namespace System.IO

Set-StrictMode -Version 3.0

. $PSScriptRoot/Functions/Public/Read-ModuleMetadata.ps1

$script:moduleMetadata = Read-ModuleMetadata $MyInvocation
if ($script:moduleMetadata.Resources) {
    Import-LocalizedData -BindingVariable 'LocalizedData' -FileName $script:moduleMetadata.Resources.Name
}

$script:moduleMetadata.ScriptFiles | ForEach-Object { . $_ }
Export-ModuleMember -Function $script:moduleMetadata.PublicFunctionNames


<#
    Represents information about module metadata.
#>
class ModuleMetadataInfo {
    [FileInfo[]]
    $ScriptFiles

    [String[]]
    $PublicFunctionNames

    [FileInfo]
    $Resources
}


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

        [void](Join-Path $path '.')

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

        [void](Join-Path $path '.')

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

        if ($arguments -is [String]) {
            $arguments = @($arguments)
        }

        foreach ($argument in $arguments) {
            $identifier = [String]$argument

            if ([String]::IsNullOrWhiteSpace($identifier)) {
                throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
            }

            if ($identifier -notmatch '^[a-z_][a-z0-9_]*$') {
                throw [System.ArgumentException]::new('Specified string was not a correct identifier.')
            }
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

        if ($arguments -is [String]) {
            $arguments = @($arguments)
        }

        foreach ($argument in $arguments) {
            $identifier = [String]$argument

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
}


<#
    Validates specified argument as a path to a leaf or not existing entry.
#>
class ValidateNonContainerPathAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        if ($arguments -is [String]) {
            $arguments = @($arguments)
        }

        foreach ($argument in $arguments) {
            $path = [String]$argument

            if ([String]::IsNullOrWhiteSpace($path)) {
                throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
            }

            [void](Join-Path $path '.')

            if (Test-Path -Path $path -PathType Container) {
                throw [System.ArgumentException]::new('Argument cannot be a path to an existing container.')
            }
        }
    }
}


<#
    Validates specified argument as a path to a container or not existing entry.
#>
class ValidateNonLeafPathAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        if ($arguments -is [String]) {
            $arguments = @($arguments)
        }

        foreach ($argument in $arguments) {
            $path = [String]$argument

            if ([String]::IsNullOrWhiteSpace($path)) {
                throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
            }

            [void](Join-Path $path '.')

            if (Test-Path -Path $path -PathType Leaf) {
                throw [System.ArgumentException]::new('Argument cannot be a path to an existing leaf.')
            }
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

        if ($arguments -is [String]) {
            $arguments = @($arguments)
        }

        foreach ($argument in $arguments) {
            $path = [String]$argument

            if ([String]::IsNullOrWhiteSpace($path)) {
                throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
            }

            [void](Join-Path $path '.')
        }
    }
}

Export-ModuleMember -Function '*' -Variable '*' -Alias '*' -Cmdlet '*'
