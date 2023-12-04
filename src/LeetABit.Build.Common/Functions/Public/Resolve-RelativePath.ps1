#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Resolve-RelativePath {
    <#
    .SYNOPSIS
        Resolves a specified path as a relative path anchored at a specified base path.
    .DESCRIPTION
        The Resolve-RelativePath cmdlet returns a relative path between a specified path and a base path.
    .EXAMPLE
        PS> Resolve-RelativePath -Path "C:\Directory\Subdirectory\File.txt" -BasePath "C:\Directory\"

        Gets a path that is relative path to the specified item based on the specified base directory. The result is ".\Subdirectory\File.txt".
    #>
    [CmdletBinding(PositionalBinding = $False,
                   DefaultParameterSetName = 'Path')]
    [OutputType([String])]

    param (
        # The path which relative version shall be obtained.
        [Parameter(HelpMessage = "Provide path to convert.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'Path')]
        [String[]]
        $Path,

        # The path which relative version shall be obtained.
        [Parameter(HelpMessage = "Provide path to convert.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'LiteralPath')]
        [String[]]
        $LiteralPath,

        # The base path in which the relative path shall be rooted.
        [Parameter(Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $Base)

    begin {
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $SelectedPath = if ($PSCmdlet.ParameterSetName -eq 'Path') { $Path } else { $LiteralPath }
        $parameters = @{ "$($PSCmdlet.ParameterSetName)" = $SelectedPath }
        $comparison = if ($IsWindows) { [System.StringComparison]::OrdinalIgnoreCase }
                      else { [System.StringComparison]::Ordinal }
    }

    process {
        Push-Location -LiteralPath $Base
        try {
            $normalizedBasePath = ConvertTo-NormalizedPath -LiteralPath (Get-Location)
            $result = Resolve-Path -Relative @parameters
        }
        finally {
            Pop-Location
        }

        foreach ($currentPath in $result) {
            if (-not [System.IO.Path]::IsPathRooted($currentPath)) {
                $currentPath = Join-Path -Path $normalizedBasePath -ChildPath $currentPath
            }

            $currentPath = ConvertTo-NormalizedPath -LiteralPath $currentPath

            $relativePath = ''

            while ($true) {
                if ($currentPath.IndexOf($normalizedBasePath, $comparison) -eq 0) {
                    if ($currentPath.Equals($normalizedBasePath, $comparison)) {
                        $relativePath = $relativePath + '.'
                    }
                    else {
                        $length = $normalizedBasePath.Length
                        if (-not [System.IO.Path]::EndsInDirectorySeparator($normalizedBasePath)) {
                            $length = $length + 1
                        }

                        $relativePath = $relativePath + $currentPath.Substring($length)
                    }

                    break
                }
                else {
                    $relativePath = $relativePath + '..\'
                    $normalizedBasePath = Split-Path -LiteralPath $normalizedBasePath
                }
            }

            $relativePath
        }
    }
}
