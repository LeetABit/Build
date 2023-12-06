#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Get-ContainingModule {
    param (
        [ScriptBlock]
        $ScriptBlock
    )

    process {
        if ($ScriptBlock.Module) {
            return $ScriptBlock.Module
        }

        $candidatePath = Split-Path $ScriptBlock.File
        while ($candidatePath) {
            $modules = Find-ModulePath $candidatePath
            if ($modules) {
                foreach ($module in $modules) {
                    $moduleInfo = Get-Module $module -ListAvailable
                    if (Test-ModuleContainsFile -Module $moduleInfo -File $ScriptBlock.File) {
                        return $moduleInfo
                    }
                }
            }

            $candidatePath = Split-Path $candidatePath
        }
    }
}
