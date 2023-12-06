#requires -version 6
using namespace System
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.IO
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Security.Cryptography.X509Certificates
using namespace Microsoft.PowerShell.Commands
using module LeetABit.Build.Common

Set-StrictMode -Version 3.0

$script:moduleRoot = $PSScriptRoot
$script:moduleMetadata = LeetABit.Build.Common\Read-ModuleMetadata $MyInvocation
if ($script:moduleMetadata.Resources) {
    Import-LocalizedData -BindingVariable 'LocalizedData' -FileName $script:moduleMetadata.Resources.Name
}

$script:moduleMetadata.ScriptFiles | ForEach-Object { . $_ }
Export-ModuleMember -Function $script:moduleMetadata.PublicFunctionNames

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    if (Get-Module 'LeetABit.Build.Extensibility') {
        LeetABit.Build.Extensibility\Unregister-BuildExtension "LeetABit.Build.PowerShell" -ErrorAction SilentlyContinue
    }
}

LeetABit.Build.Extensibility\Register-BuildExtension -Resolver {
    param (
        [String]
        $ResolutionRoot
    )

    process {
        Find-ProjectPath -LiteralPath $ResolutionRoot
    }
}

LeetABit.Build.Extensibility\Register-BuildTask "clean" {
    <#
    .SYNOPSIS
        Cleans artifacts produced for the specified project.
    #>

    param (
        [String]
        $ProjectPath,

        [String]
        $SourceRoot,

        [String]
        $ArtifactsRoot
    )

    process {
        Clear-Project -LiteralPath $ProjectPath -SourceRoot $SourceRoot -ArtifactsRoot $ArtifactsRoot
    }
}

LeetABit.Build.Extensibility\Register-BuildTask "codegen" -Jobs {}
#(Get-Item -Path function:Write-ProjectProperties).ScriptBlock


LeetABit.Build.Extensibility\Register-BuildTask "build" "codegen", {
    <#
    .SYNOPSIS
        Builds artifacts for the specified project.
    #>

    param(
        [String]
        $ProjectPath,

        [String]
        $SourceRoot,

        [String]
        $ArtifactsRoot
    )

    process {
        Build-Project -LiteralPath $ProjectPath -SourceRoot $SourceRoot -ArtifactsRoot $ArtifactsRoot
    }
}

LeetABit.Build.Extensibility\Register-BuildTask "rebuild" ("clean", "build")

LeetABit.Build.Extensibility\Register-BuildTask "analyze" "rebuild", {
    <#
    .SYNOPSIS
        Analyzes artifacts of the specified project.
    #>

    param(
        [String]
        $ProjectPath,

        [String]
        $ArtifactsRoot
    )

    process {
        Invoke-ProjectAnalysis -ProjectPath $ProjectPath -ArtifactsRoot $ArtifactsRoot
    }
}

LeetABit.Build.Extensibility\Register-BuildTask "test" "analyze", {
    <#
    .SYNOPSIS
        Tests specified project.
    #>

    param(
        [String]
        $ProjectPath,

        [String]
        $TestRoot,

        [String]
        $ArtifactsRoot
    )

    process {
        Test-Project -ProjectPath $ProjectPath -TestRoot $TestRoot -ArtifactsRoot $ArtifactsRoot
    }
}


LeetABit.Build.Extensibility\Register-BuildTask "sign" "test", {
    <#
    .SYNOPSIS
        Digitally signs the artifacts of the specified project.
    .PARAMETER Certificate
        Code Sign certificate to be used.
    .PARAMETER CertificatePath
        PowerShell Certificate Store path to the Code Sign certificate.
    .PARAMETER TimestampServer
        Code Sign Timestamp Server to be used.
    #>

    param(
        [String]
        $ProjectPath,

        [String]
        $SourceRoot,

        [String]
        $ArtifactsRoot,

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
        $TimestampServer
    )

    process {
        $certificateParameters = @{}

        if ($PSCmdlet.ParameterSetName -eq 'Certificate') {
            $certificateParameters['Certificate'] = $Certificate
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'CertificatePath') {
            $certificateParameters['CertificatePath'] = $CertificatePath
        }

        Set-CodeSignature -ProjectPath $ProjectPath -SourceRoot $SourceRoot -ArtifactsRoot $ArtifactsRoot -TimestampServer $TimestampServer @certificateParameters
    }
}

LeetABit.Build.Extensibility\Register-BuildTask "pack" -IsDefault "sign", {
    param(
        [String]
        $ProjectPath,

        [String]
        $SourceRoot,

        [String]
        $ArtifactsRoot
    )

    process {
        Save-ProjectPackage -ProjectPath $ProjectPath -SourceRoot $SourceRoot -ArtifactsRoot $ArtifactsRoot
    }
}

LeetABit.Build.Extensibility\Register-BuildTask "publish" "pack", {
    param(
        [String]
        $ProjectPath,

        [String]
        $SourceRoot,

        [String]
        $ArtifactsRoot,

        [String]
        $NugetApiKey)

    process {
        Publish-Project -ProjectPath $ProjectPath -SourceRoot $SourceRoot -ArtifactsRoot $ArtifactsRoot -NugetApiKey $NugetApiKey
    }
}

LeetABit.Build.Extensibility\Register-BuildTask "docgen" "build", {
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
        Write-ReferenceDocumentation -ProjectPath $ProjectPath -SourceRoot $SourceRoot -ArtifactsRoot $ArtifactsRoot -ReferenceDocsRoot $ReferenceDocsRoot
    }
}
