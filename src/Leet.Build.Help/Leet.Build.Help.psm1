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
function Invoke-OnHelpCommand ([String] $HelpTopic) {
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

    foreach ($extension in (Leet.Build.Commands\Get-CommandModules -IncludeExtensions)) {
        foreach ($exportedCommand in $extension.ExportedCommands.Keys) {
            if ($exportedCommand -match "^Invoke-On(.*)Command$") {
                if (-not $mapping[$exportedCommand]) {
                    $mapping[$exportedCommand] = @()
                }
    
                $mapping[$exportedCommand] += $extension
            }
        }
    }
    
    foreach ($functionName in $mapping.Keys) {
        if ($functionName -match "^Invoke-On(.*)Command$") {
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

    foreach ($extension in (Leet.Build.Commands\Get-CommandModules -IncludeExtensions)) {
        foreach ($exportedCommand in $extension.ExportedCommands.Keys) {
            if ($exportedCommand -match "^Invoke-On$($CommandName)Command$") {
                $found = $true
                $helpStructure = Get-Help $extension\$exportedCommand -Full
                $help          = (Get-Help $extension\$exportedCommand | Out-String)
                $startIndex    = $help.IndexOf("SYNTAX") + "SYNTAX".Length
                $endIndex      = $help.IndexOf("DESCRIPTION", $startIndex)
                $syntaxText    = $help.Substring($startIndex, $endIndex - $startIndex)
                $syntaxSets = $syntaxText -split ([Environment]::NewLine + [Environment]::NewLine)

                Write-Message
                Write-Message -Message "[$extension]"
                Write-Message -Message "SYNOPSIS"
                Write-Message -Message "$($helpStructure.Synopsis)" -Indentation 4
                Write-Message

                Write-Message -Message "SYNTAX"
                foreach ($syntaxSet in $syntaxSets) {
                    $syntax = Get-SubstringLinewise $syntaxSet
                    if ($syntax -match "Invoke-On$CommandName`Command\s+(.*)\s+\[\<CommonParameters\>") {
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
        }
    }

    if (-not $found) {
        throw "Could not find help topic for '$CommandName' command."
    }
}

<#
.SYNOPSIS
Gets a part of each of the specified string line.

.PARAMETER Text
Text which substring shall be obtained.

.PARAMETER Index
Index at which a substring of the each line of the $Text shall be taken.
#>
function Get-SubstringLinewise ( [String] $Text  ,
                                 [Int]    $Index ) {
    $lines = $Text -split [Environment]::NewLine
    for ($i = 0; $i -lt $lines.Length; ++$i) {
        if ($lines[$i].Length -ge $Index) {
            $lines[$i] = $lines[$i].Substring($Index)
        }
    }

    return $lines -join ""
}

<#
.SYNOPSIS
Gets the name of the base script file that is calling Leet.Build module.
#>
function Get-BaseScriptName {
    $result = $null
    
    Get-PSCallStack | Foreach-Object {
        if ($_.ScriptName -and ($_.ScriptName -notlike "*.psm1")) {
            $item = Get-Item $_.ScriptName
            if (-not $result) {
                $result = $item.Basename + $item.Extension
            }
        }
    }
    
    if (-not $result) {
        $result = "run.ps1"
    }
    
    return $result
}


Export-ModuleMember -Variable '*' -Alias '*' -Function '*' -Cmdlet '*'
