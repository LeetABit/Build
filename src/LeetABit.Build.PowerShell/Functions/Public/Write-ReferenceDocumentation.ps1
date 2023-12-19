#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Write-ReferenceDocumentation {
    param(
        [String]
        $ProjectPath,
        [String]
        $SourceRoot,
        [String]
        $ArtifactsRoot,
        [String]
        $ReferenceDocsRoot
    )

    process {
        $RelativeProjectPath = Resolve-RelativePath -Path $ProjectPath -Base $SourceRoot
        if (-not $PSBoundParameters.Keys.Contains('ReferenceDocsRoot') -or -not $ReferenceDocsRoot) {
            $ReferenceDocsRoot = $ArtifactsRoot
        }

        $outputPath = Join-Path $ReferenceDocsRoot $RelativeProjectPath
        $artifactPath = Join-Path $ArtifactsRoot $RelativeProjectPath

        if (Test-Path $artifactPath -PathType Container) {
            $itemPath = Get-Item $artifactPath
            $publicFunctionsPath = Join-Path $itemPath.FullName "Functions" "Public"
            if (Test-Path $publicFunctionsPath -PathType Container) {
                $functions = Get-ChildItem $publicFunctionsPath -Filter '*.ps1'

                foreach ($function in $functions.BaseName) {
                    Write-Message "Generating documentation for cmdlet: '$function'."
                    $ParamList = @{
                        ArtifactPath = $artifactPath
                        PowerShellRoot = (Join-Path $PSScriptRoot ".." "..")
                        FunctionName = $function
                        OutputPath = $outputPath
                    }

                    $PowerShell = [powershell]::Create()
                    [void]$PowerShell.AddScript({
                        Param ($ArtifactPath, $PowerShellRoot, $FunctionName, $OutputPath)

                        try {
                            $module = Import-Module $ArtifactPath -PassThru
                            if (-not (Get-Module -Name LeetABit.Build.PowerShell)) {
                                Import-Module $PowerShellRoot
                            }

                            $helpItem = Get-Help ($module.ExportedFunctions[$FunctionName]) -Full
                            $markdownFilePath = Join-Path $OutputPath "$($FunctionName).md"
                            if (-not (Test-Path $markdownFilePath -PathType Leaf)) {
                                $null = New-Item $markdownFilePath -ItemType File -Force
                            }

                            LeetABit.Build.PowerShell\Get-Markdown $helpItem |
                                Set-Content -Path $markdownFilePath
                        }
                        catch {
                            $_
                        }
                    }).AddParameters($ParamList)
                    try {
                        $errorItem = $PowerShell.Invoke()

                        if ($errorItem) {
                            throw ( New-Object System.Management.Automation.RuntimeException( "Could not generate documentation for function '$function'.", $Null, $errorItem[0] ) )
                        }
                        elseif ($PowerShell.HadErrors) {
                            throw $PowerShell.Streams.Error[0].Exception
                        }
                    }
                    finally {
                        $PowerShell.Dispose()
                    }
                }
            }
        }
        elseif ($artifactPath.EndsWith(".ps1")) {
            $helpItem = Get-Help $artifactPath -Full
            $itemPath = Get-Item $artifactPath
            $dir = Split-Path $outputPath
            if (-not (Test-Path $dir -PathType Container)) {
                if (Test-Path $dir -PathType Leaf) {
                    Remove-Item $dir -Force
                }

                [void](New-Item $dir -ItemType Directory -Force)
            }

            Get-Markdown $helpItem |
                Set-Content -Path (Join-Path (Split-Path $outputPath) "$($itemPath.BaseName).md")
        }
    }
}
