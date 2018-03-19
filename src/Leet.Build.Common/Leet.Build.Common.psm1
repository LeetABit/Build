#requires -version 6

Set-StrictMode -Version 2

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'Continue'

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
