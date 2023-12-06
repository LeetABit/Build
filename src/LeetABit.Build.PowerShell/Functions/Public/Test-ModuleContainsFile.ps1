#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Test-ModuleContainsFile
{
    param (
        [PSModuleInfo]
        $Module,

        [String]
        $FilePath
    )

    begin {
        $normalizedFilePAth = (LeetABit.Build.Common\ConvertTo-NormalizedPath $FilePath)
    }

    process {
        $moduleDirPath = Split-Path (LeetABit.Build.Common\ConvertTo-NormalizedPath $Module.Path)

        foreach ($file in ($Module.FileList + (LeetABit.Build.Common\ConvertTo-NormalizedPath (Join-Path $moduleDirPath $Module.RootModule)))) {
            if ($normalizedFilePAth -eq $file) {
                return $true
            }
        }

        return $false
    }
}
