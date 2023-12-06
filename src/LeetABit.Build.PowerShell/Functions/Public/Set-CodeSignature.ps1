#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Set-CodeSignature {
    <#
    .SYNOPSIS
        Handler for PowerShell 'sign' target.
    .PARAMETER ProjectPath
        Path to the project which output shall be signed.
    .PARAMETER ArtifactsRoot
        Location of the repository artifacts directory to which the PowerShell files shall be copied.
    .PARAMETER SourceRoot
        Path to the project source directory.
    .PARAMETER Certificate
        Code Sign certificate to be used.
    .PARAMETER CertificatePath
        Path to the Code Sign certificate to be used.
    .PARAMETER TimestampServer
        Code Sign Timestamp Server to be used.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   DefaultParameterSetName = 'CertificatePath',
                   SupportsShouldProcess = $True)]
    param (
        [String]
        $ProjectPath,

        [Parameter(HelpMessage = 'Provide path to the repository artifacts directory to which the PowerShell files shall be copied.',
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $ArtifactsRoot,

        [String]
        $SourceRoot,

        [Parameter(Position = 2,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'Certificate')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        [Parameter(Position = 2,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'CertificatePath')]
        [String]
        $CertificatePath,

        [Parameter(Position = 3,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $TimestampServer)

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $RelativeProjectPath = Resolve-RelativePath -Path $ProjectPath -Base $SourceRoot
        $artifactPath = Join-Path $ArtifactsRoot $RelativeProjectPath

        $certificateParameters = @{}
        if ($PSCmdlet.ParameterSetName -eq 'Certificate') {
            $certificateParameters['Certificate'] = $Certificate
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'CertificatePath') {
            if (-not $CertificatePath) {
                return
            }

            $certificateParameters['CertificatePath'] = $CertificatePath
        }

        if (Test-Path -Path $artifactPath -PathType Container) {
            Get-ChildItem -Path $artifactPath -Include ('*.psd1', '*.ps1', '*.psm1', '*.ps1xml') -Recurse | ForEach-Object {
                if ($PSCmdlet.ShouldProcess($LocalizedData.Resource_DigitalSignatureOnFile -f $_,
                                            $LocalizedData.Operation_Set)) {
                    LeetABit.Build.Common\Set-DigitalSignature -Path $_ -TimestampServer $TimestampServer @certificateParameters
                }
            }

            $moduleName = Split-Path $artifactPath -Leaf
            $catalogFile = Join-Path $artifactPath "$moduleName.cat"
            if (Test-Path $catalogFile) {
                Remove-Item -Path $catalogFile -Force
            }

            $null = New-FileCatalog -CatalogFilePath $catalogFile -CatalogVersion 2.0 -Path $artifactPath
            if ($PSCmdlet.ShouldProcess($LocalizedData.Resource_DigitalSignatureOnFile -f $catalogFile,
                                        $LocalizedData.Operation_Set)) {
                LeetABit.Build.Common\Set-DigitalSignature -Path $catalogFile -TimestampServer $TimestampServer @certificateParameters
            }
        }
        elseif ($artifactPath.EndsWith(".ps1")) {
            if ($PSCmdlet.ShouldProcess($LocalizedData.Resource_DigitalSignatureOnFile -f $artifactPath,
                                        $LocalizedData.Operation_Set)) {
                LeetABit.Build.Common\Set-DigitalSignature -Path $artifactPath -TimestampServer $TimestampServer @certificateParameters
            }
        }
   }
}
