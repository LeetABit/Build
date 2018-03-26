#requires -version 6

Set-StrictMode -Version 2

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'Continue'

<#
.SYNOPSIS
Gets help for the build script or one of its commands.

.PARAMETER HelpTopic
Name of the command for which the help text shall be obtained.
#>
function Invoke-OnLeetBuildHelpCommand ([String] $HelpTopic) {
    if ($HelpTopic) {
        Write-CommandHelp $HelpTopic
    } else {
        Write-GeneralHelp
    }
}

<#
.SYNOPSIS
Writes general help about build scripts usage.
#>
function Write-GeneralHelp() {
    $scriptName = Join-Path '.' (Get-BaseScriptName)
    
    Write-Message
    Write-Message -Message "NAME"
    Write-Message -Message $scriptName -Indentation 4
    Write-Message
    Write-Message -Message "SYNOPSIS"
    Write-Message -Message "Provides bootstrapping for Leet.Build scripts." -Indentation 4
    Write-Message
    Write-Message -Message "SYNTAX"
       
    $mapping = @{}

    foreach ($exportedCommand in Get-CommandFunctions -IncludeExtensions) {
        if (-not $mapping[$exportedCommand.Name]) {
            $mapping[$exportedCommand.Name] = @()
        }

        $mapping[$exportedCommand.Name] += $exportedCommand.Module
    }
    
    foreach ($functionName in $mapping.Keys) {
        if ($functionName -match "^Invoke-OnLeetBuild(.*)Command$") {
            Write-Message -Message "$scriptName $(($matches[1]).ToLower())" -Indentation 4
            foreach ($extension in $mapping[$functionName]) {
                $help = Get-Help $extension\$functionName
                Write-Message -Message "[$extension]: $($help.Synopsis)" -Indentation 8
            }
        }
    
        Write-Message
    }
}

<#
.SYNOPSIS
Writes help about specified build command.

.PARAMETER CommandName
Name of the command for which a help message shall be obtained.
#>
function Write-CommandHelp([String] $CommandName) {
    $found    = $false
    $fileName = Join-Path '.' $(Get-BaseScriptName)

    foreach ($commandFunction in Get-CommandFunctions $CommandName -IncludeExtensions) {
        $commandModule = $commandFunction.Module
        $found = $true
        $helpStructure = Get-Help "$($commandModule.Name)\$($commandFunction.Name)" -Full
        $help          = (Get-Help "$($commandModule.Name)\$($commandFunction.Name)" | Out-String)
        $startIndex    = $help.IndexOf("SYNTAX") + "SYNTAX".Length
        $endIndex      = $help.IndexOf("DESCRIPTION", $startIndex)
        $syntaxText    = $help.Substring($startIndex, $endIndex - $startIndex)
        $syntaxSets = $syntaxText -split ([Environment]::NewLine + [Environment]::NewLine)

        Write-Message
        Write-Message -Message "[$($commandModule.Name)]"
        Write-Message -Message "SYNOPSIS"
        Write-Message -Message "$($helpStructure.Synopsis)" -Indentation 4
        Write-Message

        Write-Message -Message "SYNTAX"
        foreach ($syntaxSet in $syntaxSets) {
            $syntax = Get-SubstringLinewise $syntaxSet
            if ($syntax -match "Invoke-OnLeetBuild$CommandName`Command\s+(.*)\s+\[\<CommonParameters\>") {
                Write-Message -Message "$fileName $CommandName $($matches[1])" -Indentation 4
            } else {
                Write-Message -Message "$fileName $CommandName" -Indentation 4
            }
        }
                
        Write-Message

        Write-Message -Message "PARAMETERS"
        if ($helpStructure.parameters.PSobject.Properties.Name -contains 'parameter') {
            foreach ($parameter in $helpStructure.parameters.parameter) {
                Write-Message -Message "$($parameter.Name)" -Indentation 4
                if (Get-Member -InputObject $parameter -Name "description" -ErrorAction SilentlyContinue) {
                    Write-Message -Message "$($parameter.description.Text)" -Indentation 8
                }
            }
        }
        
        Write-Message
    }

    if (-not $found) {
        throw "Could not find help topic for '$CommandName' command."
    }
}

Export-ModuleMember -Variable '*' -Alias '*' -Function '*' -Cmdlet '*'
