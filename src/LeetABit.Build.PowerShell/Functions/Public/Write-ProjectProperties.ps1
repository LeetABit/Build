#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections.Generic
using namespace System.IO

Set-StrictMode -Version 3.0

function Write-ProjectProperties {
    param(
        [String]
        $ProjectPath,
        [String]
        $SourceRoot,
        [String]
        $Version,
        [String]
        $PrereleaseVersion,
        [String[]]
        $ReleaseNotes
    )

    process {
        $TaskName = LeetABit.Build.Arguments\Find-CommandArgument -ParameterName 'TaskName' -DefaultValue 'codegen'
        $projects = Resolve-Project $SourceRoot 'LeetABit.Build.Repository' $TaskName
        $modules = $projects | Where-Object { ($_[1] -eq 'LeetABit.Build.PowerShell') -and (Test-Path $_[0] -PathType Container)} | ForEach-Object { Split-Path $_[0] -Leaf }

        $projectItem = Get-Item $ProjectPath
        $manifestPath = Join-Path $projectItem.FullName "$($projectItem.BaseName).psd1"
        if (Test-Path $manifestPath -PathType Leaf) {
            $content = [List[String]](Get-Content $manifestPath)

            if (Test-Path $ProjectPath -PathType Container) {
                $scriptsPath = Join-Path $ProjectPath 'Scripts'
                $files = Get-ChildItem -Path $ProjectPath -File -Recurse |
                        Foreach-Object { $_.FullName } |
                        Where-Object { $_ -ne $manifestPath } |
                        ForEach-Object { "        '$(Resolve-RelativePath $_ $ProjectPath)'" }
                if ((Test-Path $scriptsPath -PathType Container) -and (Get-ChildItem -Path $scriptsPath -File)) {
                    $functions = @()
                    $lines = @()
                    $directories = [Stack]@($scriptsPath)

                    while ($directories.Count -gt 0) {
                        $directory = $directories.Pop()
                        $relative = Resolve-RelativePath $directory $scriptsPath
                        $depth = if ($relative -eq '.') { 0 } else { $relative.Split([Path]::DirectorySeparatorChar).Count }
                        $subdirectoryName = [Path]::GetFileName($directory)
                        $lines += "$("    " * ($depth + 2))# $subdirectoryName"

                        Get-ChildItem $directory -File | ForEach-Object {
                            $relaativePath = Resolve-RelativePath $_.FullName $ProjectPath
                            $lines += "$("    " * ($depth + 2))'.$([Path]::DirectorySeparatorChar)$relaativePath'"
                            $fileName = [Path]::GetFileNameWithoutExtension($relaativePath)
                            if ($subdirectoryName -ne 'Private' -and $fileName.Contains('-')) {
                                $functions += "        '$fileName'"
                            }
                        }

                        $subdirectories = @(Get-ChildItem $directory -Directory)
                        [array]::Reverse($subdirectories)
                        $subdirectories | ForEach-Object {
                            $directories.Push($_.FullName)
                        }
                    }

                    $content = Update-MultilineProperty -lines $content -BeginingPattern '    NestedModules = @(' -EndPattern '    )' -Content $lines

                    $content = Update-MultilineProperty -lines $content -BeginingPattern '    FunctionsToExport = @(' -EndPattern '    )' -Content $functions
                }

                $content = Update-MultilineProperty -lines $content -BeginingPattern '    FileList = @(' -EndPattern '    )' -Content $files

                $content = Update-MultilineProperty -lines $content -BeginingPattern '            ReleaseNotes = @"' -EndPattern '"@' -Content $ReleaseNotes

                for ($i = 0; $i -lt $content.Count; $i = $i + 1) {
                    if ($PrereleaseVersion) {
                        $content = $content -replace "^(\s+)Prerelease = '[^']*'", "`$1Prerelease = '$PrereleaseVersion'"
                    }
                    $content = $content -replace "^(\s+)ModuleVersion = '\d+\.\d+\.\d+'", "`$1ModuleVersion = '$Version'"
                    $modules | ForEach-Object {
                        $content = $content -replace "@{ModuleName = '$_'; ModuleVersion = '\d+.\d+.\d+'; }", "@{ModuleName = '$_'; ModuleVersion = '$Version'; }"
                    }
                }

                $content | Out-File $manifestPath
            }
        }
    }
}
