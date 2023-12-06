#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Invoke-ProjectAnalysis {
    param(
        [String]
        $ProjectPath,
        # Location of the repository artifacts directory to which the PowerShell files shall be copied.
        [Parameter(HelpMessage = 'Provide path to the repository artifacts directory to which the PowerShell files shall be copied.',
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $ArtifactsRoot,
        [String[]]
        $CustomRulePath
    )

    process {
        $RelativeProjectPath = Resolve-RelativePath -Path $ProjectPath -Base $SourceRoot
        $artifactPath = Join-Path $ArtifactsRoot $RelativeProjectPath

        $MyInvocation.MyCommand.Module.PrivateData.AnalyzeDependencies | LeetABit.Build.Common\New-PSObject | Install-DependencyModule

        Import-Module PSScriptAnalyzer -Force
        $violations = @()

        while ($true) {
            try {
                $violations += PSScriptAnalyzer\Invoke-ScriptAnalyzer $artifactPath -ErrorAction SilentlyContinue -Recurse
                break
            }
            catch [System.NullReferenceException] { }
        }

        while ($true) {
            try {
                $violations += PSScriptAnalyzer\Invoke-ScriptAnalyzer $artifactPath -CustomRulePath $script:moduleRoot -Recurse -ErrorAction SilentlyContinue
                break
            }
            catch [System.NullReferenceException] { }
        }

        if ($CustomRulePath) {
            while ($true) {
                try {
                    $violations += $CustomRulePath | ForEach-Object {
                        PSScriptAnalyzer\Invoke-ScriptAnalyzer $artifactPath -CustomRulePath $_ -Recurse -ErrorAction SilentlyContinue
                    }

                    break
                }
                catch [System.NullReferenceException] { }
            }
        }

        $violations | ForEach-Object { Write-Warning (($_ | Out-String).Trim() + [Environment]::NewLine) }
    }
}
