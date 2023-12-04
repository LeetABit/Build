#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Set-DigitalSignature {
    <#
    .SYNOPSIS
        Sets an Authenticode signature for a specified item.
    .DESCRIPTION
        The Set-DigitalSignature cmdlet adds an Authenticode signature to any file that supports Subject Interface Package (SIP). If there is a signature in the file when this cmdlet runs, that signature is removed.
    .PARAMETER Path
        Path to the file that shall be signed.
    .PARAMETER CertificatePath
        PowerShell Certificate Store path to the Code Sign certificate.
    .PARAMETER Certificate
        Code Sign certificate to be used.
    .PARAMETER TimestampServer
        Code Sign Timestamp Server to be used.
    .EXAMPLE
        PS> Set-DigitalSignature -ArtifactPath "C:\artifact.dll" -Certificate $cert

        Digitally signs the specified file using specified code sign certificate.
    .EXAMPLE
        PS> Set-DigitalSignature -ArtifactPath "C:\artifact.dll" -CertificatePath "cert:\LocalMachine\My\$CertFingerprint" -TimestampServer "http://timeserver.example.com"

        Digitally signs the specified file using certificate located under specified path in the store and adds timestamp to the signature.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = "Low",
                   DefaultParameterSetName = 'CertificatePath')]
    [OutputType([System.Management.Automation.Signature])]

    param (
        [Parameter(HelpMessage = 'Provide path to the file that shall be signed.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $Path,

        [Parameter(HelpMessage = 'Provide path to the Code Sign certificate.',
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'CertificatePath')]
        [String]
        $CertificatePath,

        [Parameter(HelpMessage = 'Provide Code Sign certificate.',
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'Certificate')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        [Parameter(Position = 2,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $TimestampServer)

    begin {
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'CertificatePath') {
            if ($CertificatePath) {
                $Certificate = Get-ChildItem -Path $CertificatePath -CodeSigningCert
            }
        }

        foreach ($filePath in $Path) {
            Write-Diagnostic ($LocalizedData.Signing_FilePath -f (Split-Path $filePath -Leaf))
            if ($PSCmdlet.ShouldProcess($LocalizedData.Resource_AuthenticodeSignature_FilePath -f $filePath,
                                        $LocalizedData.Operation_Set)) {
                $result = Set-AuthenticodeSignature -FilePath $filePath -Certificate $Certificate -TimestampServer $TimestampServer -HashAlgorithm SHA256
                if ($result.Status -ne 'Valid') {
                    Write-Error ($LocalizedData.ErrorSigning_Path_Message -f ($filePath, $result.StatusMessage))
                }
            }
        }
    }
}
