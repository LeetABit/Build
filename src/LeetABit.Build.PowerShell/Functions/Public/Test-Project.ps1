#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Test-Project {
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
        $TestRoot,

        [String]
        $ArtifactsRoot
    )

    process {
        $MyInvocation.MyCommand.Module.PrivateData.TestDependencies | LeetABit.Build.Common\New-PSObject | Install-DependencyModule

        $RelativeProjectPath = Resolve-RelativePath -Path $ProjectPath -Base $SourceRoot
        $testPath = Join-Path $TestRoot $RelativeProjectPath
        if (-not (Test-Path $testPath)) {
            return;
        }

        $data = @{ ArtifactsRoot = $ArtifactsRoot; TestRoot = $TestRoot }

        Get-ChildItem -Path $testPath -Filter '*.Tests.ps1' -Recurse -File | ForEach-Object {
            $container = New-TestContainer -Path $_.FullName -Data $data
            $testResults = Invoke-Pester -Container $container -PassThru -Output None

            $describe = @{ "Name" = $Null }

            foreach ($testResult in $testResults.Tests) {
                if ($describe.Name -ne $testResult.Path[0]) {
                    if ($describe.Name) {
                        New-PSObject 'LeetABit.Build.PesterDescribeResult' $describe | Out-String | Write-Information
                    }

                    $describe = @{}
                    $describe.Name = $testResult.Path[0]
                    $describe.Failures = @()
                    $describe.TestsPassed = 0
                }

                if ($testResult.Passed) {
                    $describe.TestsPassed = $describe.TestsPassed + 1
                }
                else {
                    $failure = @{}
                    $failure.Name = $testResult.Name
                    $failure.Parameters = ConvertTo-ExpressionString $testResult.Data
                    $failure.Message = $testResult.FailureMessage.Replace('`r', [String]::Empty).Replace('`n', [String]::Empty)
                    $describe.Failures += New-PSObject 'LeetABit.Build.PesterTestFailure' $failure
                }
            }

            if ($describe) {
                New-PSObject 'LeetABit.Build.PesterDescribeResult' $describe | Out-String | Write-Information
            }
        }
    }
}
