#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Save-ProjectPackage {
    param(
        [String]
        $ProjectPath,
        [String]
        $SourceRoot,
        [String]
        $ArtifactsRoot
    )

    process {
        $RelativeProjectPath = Resolve-RelativePath -Path $ProjectPath -Base $SourceRoot
        $artifactPath = Join-Path $ArtifactsRoot $RelativeProjectPath | Convert-Path

        if (Test-Path $artifactPath -PathType Leaf -Exclude '*.ps1') {
            return
        }

        $guid = [String](New-Guid)

        $repositoryPath = "$artifactPath$guid"

        [void](New-Item $repositoryPath -ItemType Directory)

        try {
            [void](Register-PSRepository -Name $guid -SourceLocation $repositoryPath -ScriptSourceLocation $repositoryPath)
            try {
                if (Test-Path -Path $artifactPath -PathType Leaf) {
                    try {
                        if (-not (Test-ScriptFileInfo -Path $artifactPath -ErrorAction SilentlyContinue)) {
                            return
                        }
                    }
                    catch {
                        return
                    }

                    Publish-Script -Path $artifactPath -Repository $guid
                }
                else {
                    Publish-Module -Path $artifactPath -Repository $guid
                }
            }
            finally {
                Unregister-PSRepository -Name $guid
            }

            if (Test-Path -Path $artifactPath -PathType Leaf) {
                $archivePath = Join-Path (Split-Path $artifactPath) "$((Get-Item -Path $artifactPath).BaseName).zip"
                $contentPath = $artifactPath
            }
            else {
                $archivePath = Join-Path $artifactPath "$((Get-Item -Path $artifactPath).Name).zip"
                $contentPath = Resolve-Path "$artifactPath\*"
            }

            Compress-Archive -Path $contentPath -DestinationPath $archivePath -Update

            $nupkg = Join-Path $repositoryPath "*.nupkg"
            $nupkgPath = Get-Item $nupkg

            $destinationPath = if (Test-Path $artifactPath -PathType Leaf) {
                Join-Path (Get-Item $artifactPath).DirectoryName $nupkgPath.Name
            }
            else {
                $artifactPath
            }

            if (Test-Path -Path $artifactPath -PathType Container) {
                $moduleName = (Get-Item $ProjectPath).BaseName

                $nupkgDestinationDir = Join-Path $nupkgPath.DirectoryName $nupkgPath.BaseName
                $progressBackup = $global:ProgressPreference
                $global:ProgressPreference = 'SilentlyContinue'
                Expand-Archive -Path $nupkgPath.FullName -DestinationPath $nupkgDestinationDir
                $global:ProgressPreference = $progressBackup

                Remove-Item $nupkgPath.FullName -Recurse -Force

                $data = Import-PowerShellDataFile -Path (Join-Path $nupkgDestinationDir ($moduleName + ".psd1"))

                $xmlFile = Join-Path $nupkgDestinationDir ($moduleName + ".nuspec")
                [xml]$xmlDoc = Get-Content ($xmlFile)
                $dependencies = $xmlDoc.CreateElement("dependencies", $xmlDoc.package.xmlns)
                [void]$xmlDoc.package.metadata.AppendChild($dependencies)

                foreach ($d in $data.RequiredModules) {
                    $dep = $xmlDoc.CreateElement("dependency", $xmlDoc.package.xmlns)
                    $idAtt = $xmlDoc.CreateAttribute("id")
                    $idAtt.Value = $d.ModuleName
                    [void]$dep.Attributes.Append($idAtt)

                    $versionAtt = $xmlDoc.CreateAttribute("version")
                    $versionAtt.Value = $d.ModuleVersion
                    [void]$dep.Attributes.Append($versionAtt)

                    [void]$dependencies.AppendChild($dep)
                }

                $xmlDoc.Save($xmlFile)

                $progressBackup = $global:ProgressPreference
                $global:ProgressPreference = 'SilentlyContinue'
                Compress-Archive -Path (Join-Path $nupkgDestinationDir "*") -DestinationPath (Join-Path $artifactPath ($nupkgPath.BaseName + ".nupkg"))
                $global:ProgressPreference = $progressBackup
            }
            else {
                Move-Item -Path $nupkgPath.FullName -Destination $destinationPath
            }
        }
        finally {
            Remove-Item $repositoryPath -Recurse -Force
        }
    }
}
