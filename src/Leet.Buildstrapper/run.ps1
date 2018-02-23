#!/usr/bin/env pwsh
#requires -version 6

<#
.SYNOPSIS
Buildstrapper script for Leet.Build toolchain.

.DESCRIPTION
This buildstrapper is responsible for installing Leet.Build from a configured feed and invoking build toolchain.

.PARAMETER RepositoryRoot
The path to the project's repository root directory. If not specified the current script root directory will be used.

.PARAMETER LeetBuildVersion
Version of the Leet.Build tools to use. If not specified the current script will try to read it from 'Leet.Build.json' file.

.PARAMETER LeetBuildHome
Home location of the Leet.Build tools where Leet.Build modules are to be installed.

.PARAMETER LeetBuildFeed
Path to the Leet.Build tools feed to be used.
For GitHub releases use 'https://github.com/Leet/BuildTools/releases/download'
For GitHub source code use 'https://github.com/hubuk/Corelib/archive'

.PARAMETER $ForceInstallLeetBuild
Determines whether a specified version of Leet.Build shall be installed even if it is already available in the system.

.PARAMETER Arguments
Arguments to be passed to the Leet.Build toolchain.

.NOTES
The 'Leet.Build.json' file stored under 'build' subdirectory of the repository root is used as a fallback location for some of the script configuration parameters.

.EXAMPLE
Example config file:
```json
{
  "$schema": "https://raw.githubusercontent.com/Leet/BuildTools/dev/schemas/Leet.Build.schema.json",
  "LeetBuildVersion": "0.0.0"
}
```
#>
[CmdletBinding(PositionalBinding = $False)]
param( [String]   $RepositoryRoot   = $PSScriptRoot ,
       [String]   $LeetBuildVersion = $Null         ,
       [String]   $LeetBuildHome    = $Null         ,
       [String]   $LeetBuildFeed    = $Null         ,
       [Switch]   $ForceInstallLeetBuild            ,
       [Parameter(ValueFromRemainingArguments = $True)]
       [String[]] $Arguments
)

Set-StrictMode -Version 2

$ErrorActionPreference   = 'Stop'
$WarningPreference       = 'Continue'

$LastFoldName    = ""
$ImportedModules = @()

$StepColor         = [char]0x001b + '[0;36m'
$ModificationColor = [char]0x001b + '[1;35m'
$SuccessColor      = [char]0x001b + '[0;32m'
$DefaultColor      = [char]0x001b + '[0m'

<#
.SYNOPSIS
Invokes main script's procedure.
#>
function Invoke-MainScript () {
    try {
        Write-Invocation (Get-Variable -Name MyInvocation -Scope 1 -ValueOnly)
        Initialize-ScriptConfiguration
        Install-LeetBuild
        Import-LeetBuildModules
    } finally {
        Remove-ImportedLeetBuildModules
        Write-Host
    }
}

<#
.SYNOPSIS
Initializes the script by loading parameter values from configuration file or using default predefined values.

.NOTES
If the script parameter values are not specified they may be loaded from Leet.Build.json configuration file.
This configuration file should be located in 'build' subdirectory of the folder specified in $script:RepositoryRoot variable.
If the parameter value is not specified at command-line level nor in the configuration file then a default predefined value is being assigned to it or an error is being thrown depending on the parameter's nature. 
#>
function Initialize-ScriptConfiguration {
    Initialize-ConfigurationFromFile

    Initialize-LeetBuildVersion
    Initialize-LeetBuildHome
    Initialize-LeetBuildFeed
}

<#
.SYNOPSIS
Initializes a script configuration values from Leet.Build.json configuration file.
#>
function Initialize-ConfigurationFromFile {
    $configFilePath = Join-Paths $script:RepositoryRoot ('build', 'Leet.Build.json')
    Write-Verbose "Initializing configuration using '$configFilePath' as fallback file."
    $script:ConfigurationJson = $Null

    if (Test-Path $configFilePath -PathType Leaf) {
        try {
            $configFileContent = Get-Content -Raw -Encoding UTF8 -Path $configFilePath
            $script:ConfigurationJson = ConvertFrom-Json $configFileContent
        }
        catch { throw "Leet.Build.json file is not correct JSON file." }
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
Initializes $script:LeetBuildVersion configuration parameter value.

.NOTES
If no value for the parameter is not set at command-line nor in configuration file an error is thrown.
#>
function Initialize-LeetBuildVersion {
    if ($script:LeetBuildVersion) { return }

    $script:LeetBuildVersion = Get-ConfigurationFileParameterValue 'LeetBuildVersion'
    Write-Verbose "  -LeetBuildVersion = `"$script:LeetBuildVersion`""
}

<#
.SYNOPSIS
Initializes $script:LeetBuildHome parameter value if not specified by the caller.

.NOTES
If no value for the parameter is not set at command-line nor in configuration file a default value is used.
#>
function Initialize-LeetBuildHome {
    if ($script:LeetBuildHome) { return }

    $baseHome = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($env:HOME) { $env:HOME } else { $PSScriptRoot }
    $leetHome = Join-Path $baseHome '.leet'
    $script:LeetBuildHome = Get-ConfigurationFileParameterValue 'LeetBuildHome' (Join-Path $leetHome 'Leet.Build')

    Write-Verbose "  -LeetBuildHome = `"$script:LeetBuildHome`""
}

<#
.SYNOPSIS
Initializes $script:LeetBuildFeed parameter value if not specified by the caller.

.NOTES
If no value for the parameter is not set at command-line nor in configuration file a default value is used.
#>
function Initialize-LeetBuildFeed {
    if ($script:LeetBuildFeed) { return }
    
    $script:LeetBuildFeed = Get-ConfigurationFileParameterValue 'LeetBuildFeed' 'https://github.com/Leet/BuildTools/releases/download'

    Write-Verbose "  -LeetBuildFeed = `"$script:LeetBuildFeed`""
}

<#
.SYNOPSIS
Installs Leet.Build tools in a version specified by script parameters and returns a path to its directory.

.DESCRIPTION
If the Leet.Build tools in a specified version are already present in the target directory this returns.
Otherwise this function downloads them from GitHub releases and place zip content in the target directory before returning.
#>
function Install-LeetBuild {
    Write-Step -FoldName LeetBuildVersion -Message "Checking Leet.Build v$script:LeetBuildVersion availability."
    $leetBuildModulesRoot = Join-Path $script:LeetBuildHome $script:LeetBuildVersion
    
    if ($script:ForceInstallLeetBuild -or -not (Test-LeetBuildDeployed $leetBuildModulesRoot)) {
        $sourceDirectoryPath   = Join-Path $script:LeetBuildHome "Leet.Build-$LeetBuildVersion"
        $tempFilePath          = $sourceDirectoryPath + ".zip"
        $archiveExtracted      = $False
        $supportedPathSuffixes = ( ("v$script:LeetBuildVersion", 'Leet.Build.zip') ,
                                   "$script:LeetBuildVersion.zip"                  ,
                                   "Leet.Build-$script:LeetBuildVersion.zip"       )

        try {
            foreach ($suffix in $supportedPathSuffixes) {
                $sourceFilePath = Join-Paths $script:LeetBuildFeed $suffix
                if (Get-RemoteFile $sourceFilePath $tempFilePath) {
                    Write-Modification -Message "Extracting Leet.Build avchive to '$sourceDirectoryPath'."
                    Expand-Archive -Path $tempFilePath -DestinationPath $sourceDirectoryPath
                    $archiveExtracted = $True
                    break
                }
            }

            if (-not $archiveExtracted) {
                $sourceDirectoryPath = $script:LeetBuildFeed
            }

            $srcDirectory = Join-Path $sourceDirectoryPath 'src'
            if (Test-Path -Path $srcDirectory -PathType Container) {
                $sourceDirectoryPath = $srcDirectory
            }

            if (Test-Path -Path (Join-Path $sourceDirectoryPath 'Leet.Build*') -PathType Container) {
                if (Test-Path -Path $leetBuildModulesRoot -PathType Container) {
                    Write-Modification "Removing content of '$leetBuildModulesRoot' directory."
                    Remove-Item -Path $leetBuildModulesRoot -Force -Recurse -Confirm:$False
                }

                Write-Modification "Copying Leet.Build files from '$sourceDirectoryPath' to '$leetBuildModulesRoot'..."
                Copy-Item -Path $sourceDirectoryPath -Destination $leetBuildModulesRoot -Force -Container -Recurse
                $checksumFilePath = Join-Path $leetBuildModulesRoot 'Leet.Build.md5'
                Write-Modification "Writing checksum to '$checksumFilePath' file..."
                Get-DirectoryHash $sourceDirectoryPath | Out-File $checksumFilePath
            }
        } finally {
            if ($archiveExtracted) {
                Write-Modification "Removing Leet.Build archive '$tempFilePath' and temporary directory '$sourceDirectoryPath'."
                Remove-Item -Path $tempFilePath -Force -ErrorAction Continue
                Remove-Item -Path $sourceDirectoryPath -Force -ErrorAction Continue
            }
        }

        Write-Host "Leet.Build v$script:LeetBuildVersion has been installed at '$leetBuildModulesRoot'."        
    } else {
        Write-Host "Leet.Build v$script:LeetBuildVersion already installed at '$leetBuildModulesRoot'."        
    }

    $env:PSModulePath = Add-DirectoryToPath $leetBuildModulesRoot $env:PSModulePath
    Write-Success
}

<#
.SYNOPSIS
Determines whether Leet.Build is present in the specified deployment location.

.PARAMETER DeploymentPath
Path to the directory in which the Leet.Build presece shall be determined.
#>
function Test-LeetBuildDeployed ( [String] $DeploymentPath ) {
    $checksumFilePath = Join-Path $DeploymentPath 'Leet.Build.md5'

    if (! (Test-Path $checksumFilePath -PathType Leaf)) {
        return $False
    }

    $storedHash = Get-Content $ChecksumFilePath
    if ((-not $storedHash) -or $storedHash.Length -eq 0) {
        return $False
    }

    $calculatedHash = Get-DirectoryHash $DeploymentPath
    return -Not (Compare-Object $storedHash $calculatedHash -PassThru)
}

<#
.SYNOPSIS
Imports Leet.Build module from its install location.
#>
function Import-LeetBuildModules {
    Write-Step -FoldName "LeetBuildImport" -Message "Importing Leet.Build modules."

    $modulesBefore = Get-Module 'Leet.Build*'
    try {
        Get-Module 'Leet.Build*' -ListAvailable | Foreach-Object {
            Write-Host "Importing '$($_.Name)' module..."
            Import-Module $_
            $script:ImportedModules += $_
        }   
    }
    finally {
        $modulesAfter = Get-Module 'Leet.Build*'
        $script:ImportedModules = if ($modulesBefore) {
            Compare-Object $modulesAfter $modulesBefore -PassThru
        } else {
            $modulesAfter
        }
    }

    Write-Success -FoldName "LeetBuildImport"
}

<#
.SYNOPSIS
Unloads Leet.Build module.
#>
function Remove-ImportedLeetBuildModules {
    Write-Step -FoldName  "LeetBuildCleanup" -Message "Removing imported Leet.Build modules."

    $script:ImportedModules | Foreach-Object {
        Write-Host "Removing '$($_.Name)' module..."
        Remove-Module $_ -ErrorAction Continue
    }

    Write-Success -FoldName "LeetBuildCleanup"
}

<#
.SYNOPSIS
Writes to the host information about the specified invocation.

.PARAMETER Invocation
Invocation which information shall be written.
#>
function Write-Invocation( [System.Management.Automation.InvocationInfo] $Invocation ) {
    Write-Verbose "Executing: '$($Invocation.MyCommand)' with parameters:"
    $Invocation.BoundParameters.Keys | ForEach-Object {
        Write-Verbose "  -$_ = `"$($Invocation.BoundParameters[$_])`""
    }
}

<#
.SYNOPSIS
Writes a message that informs about state change in the current system.

.PARAMETER Message
Installation message to be written by the host.
#>
function Write-Modification ( [String] $Message ) {
    Write-Host "$script:ModificationColor$Message$script:DefaultColor"
}

<#
.SYNOPSIS
Writes a specified build step message string to the host.

.PARAMETER Message
Step information message to be written by the host.

.PARAMETER FoldName
Name of the fold to start if supported by the host.
#>
function Write-Step ( [String] $Message  ,
                      [String] $FoldName ) {
    $preamble = ""

    if ($env:TRAVIS) {
        $preamble = "travis_fold:start:$FoldName`r"
    }

    Write-Host "$preamble$script:StepColor$Message$script:DefaultColor"
    $script:LastFoldName = $FoldName
}

<#
.SYNOPSIS
Writes a specified build step success message string to the host.
#>
function Write-Success () {
    $preamble = ""

    if ($env:TRAVIS) {
        $preamble = "travis_fold:end:$script:LastFoldName`r"
    }

    Write-Host ("$preamble$script:SuccessColor" + "Success.$script:DefaultColor")
    Write-Host
}

<#
.SYNOPSIS
Adds a specified directory to environmental variable PATH if not yet contained.

.PARAMETER Directory
A directory to be added to the PATH.

.PARAMETER Path
A value of the environmental variable PATH to which the directory shall be added.

.NOTES
Equality for $Directory and each item in the $Path parameter is determined using [System.IO.Path]::GetFullPath method.
#>
function Add-DirectoryToPath ( [String] $Directory ,
                               [String] $Path  ) {
    $delimiter = if ($IsWindows) { ';' } else { ':' }
    $resolvedDirectory = [System.IO.Path]::GetFullPath($Directory)
    
    foreach ($item in $Path -split $delimiter) {
        $resolvedItem = [System.IO.Path]::GetFullPath($item)
        if ($resolvedDirectory -eq $resolvedItem) {
            return $Path
        }
    }
    
    return "$resolvedDirectory$delimiter$Path"
}

<#
.SYNOPSIS
Gets a collection of hashes for all files stored in the specified directory.

.PARAMETER Path
A path to the directory for which hashes shall be computed.
#>
function Get-DirectoryHash ( [String] $Path ) {
    Get-ChildItem -File -Recurse $Path -Exclude 'Leet.Build.md5' | `
        Sort-Object -Property Name | `
        Get-FileHash -Algorithm MD5 | `
        Foreach-Object { return "$($_.Hash)`t$($_.Path.Substring($Path.Length + 1))" }
}

<#
.SYNOPSIS
Obtains a specified remote file using hypertext transfer protocol (HTTP) or from network location.

.DESCRIPTION
If the remote file path is specified using HTTP protocol and there are problems obtaining the file this function performs 10 download attempts before failing.

.PARAMETER SourcePath
Path to the source file to obtain.

.PARAMETER DestinationPath
Path to the file as which the obtained file shall be saved.

.PARAMETER ThrowOnError
When this switch is set this function will throw an exception on failure otherwise a System.Boolean value is returned as an indication of success.
#>
function Get-RemoteFile ( [String] $SourcePath      ,
                          [String] $DestinationPath ,
                          [Switch] $ThrowOnError    ) {
    $result = $False
    if (Test-RemoteFileExists $SourcePath) {
        Write-Modification "Obtaining file from '$SourcePath' to '$DestinationPath'..."

        if ($SourcePath -notlike 'http*') {
            if (Test-Path $SourcePath -PathType Leaf) {
                try {
                    Copy-Item $SourcePath $DestinationPath
                    $result = $True
                }
                catch { if ($ThrowOnError) { throw } else { $result = $False } }
            }
        } else {
            try {
                Invoke-WithRetry { Invoke-WebRequest -UseBasicParsing -Uri $SourcePath -OutFile $DestinationPath }
                $result = $True
            } catch { if ($ThrowOnError) { throw } else { $result = $False } }
        }
    }

    if (-not $result -and $ThrowOnError) {
        throw "Could not get remote file '$SourcePath'."
    }

    return $result
}

<#
.SYNOPSIS
Provides a mechanism for a script block to retry its execution upon an error.

.DESCRIPTION
Invokes the specified script block. If there are errors reported during the execution this method waits specified number of seconds and retries the execution. If the speciied script block execution was retried specified number of times without success this method throws all reported errors.

.PARAMETER ScriptBlock
Script block to execute with retry.

.PARAMETER MaxAttempts
Max number of the execution attempts for the specified script block.

.PARAMETER SecondsBetweenAttempts
Number of seconds to wait between each attempt.
#>
function Invoke-WithRetry ( [ScriptBlock] $ScriptBlock,
                            [Int]         $MaxAttempts            = 1 ,
                            [Int]         $SecondsBetweenAttempts = 1 ) {
    $exceptions = @()
    for ($attempt = 0; ++$attempt -le $MaxAttempts; Start-Sleep $SecondsBetweenAttempts) {
        try   { return $ScriptBlock.Invoke() }
        catch { $exceptions += $_            }
    }
    
    throw $exceptions
}

<#
.SYNOPSIS
Combines a path with a sequence of child paths into a single path.

.DESCRIPTION
The Join-Paths cmdlet combines a path and sequence of child-paths into a single path. The provider supplies the path delimiters.

.PARAMETER Path
Specifies the main path (or paths) to which the child-path is appended. Wildcards are permitted.
The value of Path determines which provider joins the paths and adds the path delimiters. The Path parameter is required, although the parameter name ("Path") is optional.

.PARAMETER ChildPaths
Specifies the elements to append to the value of the Path parameter. Wildcards are permitted. The ChildPaths parameter is required, although the parameter name ("ChildPaths") is optional.

.NOTES
The cmdlets that contain the Path noun (the Path cmdlets) manipulate path names and return the names in a concise format that all Windows PowerShell providers can interpret. They are designed for use in programs and scripts where you want to display all or part of a path name in a particular format. Use them like you would use Dirname, Normpath, Realpath, Join, or other path manipulators.
You can use the path cmdlets with several providers, including the FileSystem, Registry, and Certificate providers.
This cmdlet is designed to work with the data exposed by any provider. To list the providers available in your session, type Get-PSProvider. For more information, see about_Providers.

.EXAMPLE
# This function call returns 'C:\First\Second\Third\Fourth.file'
Join-Paths 'C:' ('First\', '\Second', '\Third\', 'Fourth.file')
#>
function Join-Paths ( [String]   $Path       ,
                      [String[]] $ChildPaths ) {
    $isWeb = ($Path -like 'http*')
    $ChildPaths | ForEach-Object { $Path = if ($isWeb) { "$Path/$_" } else { Join-Path $Path $_ } }
    return $Path
}

<#
.SYNOPSIS
Tests whether a specified remote file exists using hypertext transfer protocol (HTTP) or from network location.

.PARAMETER SourcePath
Path to the source file to obtain.
#>
function Test-RemoteFileExists ( [String] $SourcePath ) {
    if ($SourcePath -notlike 'http*') {
        return (Test-Path $SourcePath -PathType Leaf)
    } else {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $SourcePath -Method 'Head'
        return $response.StatusCode -ne 200
    }
}

######################################################################################################################
# Main
######################################################################################################################

Invoke-MainScript
