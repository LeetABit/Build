#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Publish-Project {
    <#
    .SYNOPSIS
    Gets text that represents a markdown document for the specified PowerShell help object.
    #>

    [CmdletBinding(PositionalBinding = $False)]

    param(
        [String]
        $ProjectPath,
        [String]
        $SourceRoot,
        [String]
        $ArtifactsRoot,
        [String]
        $NugetApiKey
    )

    process {
        $RelativeProjectPath = Resolve-RelativePath -Path $ProjectPath -Base $SourceRoot
        $artifactPath = Join-Path $ArtifactsRoot $RelativeProjectPath

        $packages = if (Test-Path $artifactPath -PathType Leaf) {
            $itemPath = Get-Item $artifactPath
            Get-ChildItem -Path $itemPath.DirectoryName -Include (Join-Path $itemPath.DirectoryName "$($itemPath.BaseName).*.nupkg")
        }
        else {
            Get-ChildItem -Path $artifactPath -Include '*.nupkg' -Recurse
        }

        foreach ($package in $packages) {
            # TODO: register publish handler for file
            # 1. nuget publisher
            # 2. local file system publisher
            # 3. github release publisher

            # TODO: register tools like GIT for semver
            # TODO: register tools like GitHub for publish
            # TODO: register release command or distinguish nupkg as something else than publish
            Invoke-WebRequest -Method "PUT" -Uri "https://www.powershellgallery.com/api/v2/package/" -SslProtocol Tls12 -Headers @{ "X-NuGet-ApiKey" =  $NugetApiKey; "X-NuGet-Client-Version" = "5.7.0"} -ContentType "multipart/form-data" -InFile $package
        }
    }
}
