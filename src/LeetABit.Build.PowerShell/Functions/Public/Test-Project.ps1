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

        [String]
        $SourceRoot,

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
            $container = New-PesterContainer -Path $_.FullName -Data $data
            Invoke-Pester -Container $container
            #$testResults = Invoke-Pester -Container $container -PassThru -Output None
            #$testResults.PSObject.TypeNames.Add('LeetABit.Build.Powershell.Test.Pester')
            #$testResults

            #$describe = @{ "Name" = $Null }

            # $lastDescribe = $null
            # foreach ($testResult in $testResults.Tests) {
            #     if ($lastDescribe -ne $testResult.Path[0]) {
            #         Write-Information $testResult.Path[0]
            #         $lastDescribe = $testResult.Path[0]
            #     }

            #     #Write-Information "Heniek" -InformationAction Continue
            #     # if ($describe.Name -ne $testResult.Path[0]) {
            #     #     if ($describe.Name) {
            #     #         New-PSObject 'LeetABit.Build.PesterDescribeResult' $describe | Out-String | Write-Information
            #     #     }

            #     #     $describe = @{}
            #     #     $describe.Name = $testResult.Path[0]
            #     #     $describe.Failures = @()
            #     #     $describe.TestsPassed = 0
            #     # }

            #     # if ($testResult.Passed) {
            #     #     $describe.TestsPassed = $describe.TestsPassed + 1
            #     # }
            #     # else {
            #     #     $messages = $testResult.ErrorRecord.Exception.Message | ForEach-Object {
            #     #         $length = $_.IndexOfAny(("`r", "`n"))
            #     #         if ($length -ne -1) {
            #     #             $_.Substring(0, $length)
            #     #         } else {
            #     #             $_
            #     #         }
            #     #     }

            #     #     $failure = @{
            #     #         Name = $testResult.Name
            #     #         Message = ($messages -join [System.Environment]::NewLine)
            #     #     }

            #     #     $describe.Failures += New-PSObject 'LeetABit.Build.PesterTestFailure' $failure
            #     # }
            # }

            # if ($describe) {
            #     $null = New-PSObject 'LeetABit.Build.PesterDescribeResult' $describe | Out-String | Write-Information
            # }
        }
    }
}
