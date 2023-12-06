#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Management.Automation

Set-StrictMode -Version 3.0

function Install-DependencyModule {
    <#
    .SYNOPSIS
    Installs specified dependency PowerShell module.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = 'High')]

    param (
        # Name of the required external module dependency.
        [Parameter(HelpMessage = "Enter name of the module to install.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $ModuleName,

        # Required version of the external module dependency.
        [Parameter(HelpMessage = "Enter version of the module to install.",
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [SemanticVersion]
        $ModuleVersion)

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if (Get-Module -FullyQualifiedName @{ ModuleName=$ModuleName; ModuleVersion=$ModuleVersion }) {
            return
        }

        $moduleToUnload = Get-Module -Name $ModuleName
        $availableModules = Get-Module -FullyQualifiedName @{ ModuleName=$ModuleName; ModuleVersion=$ModuleVersion } -ListAvailable
        if (-not $availableModules) {
            if (-not (Find-Module -Name $ModuleName -RequiredVersion $ModuleVersion -AllowPrerelease)) {
                throw ("$LocalizedData.Install_DependencyModule_ModuleNotFound_ModuleName_ModuleVersion" -f ($ModuleName, $ModuleVersion))
            }

            if ($PSCmdlet.ShouldProcess("$LocalizedData.Install_DependencyModule_ShouldProcessPreferenceVariableResource",
                                        "$LocalizedData.Install_DependencyModule_ShouldProcessPreferenceVariableOperation")) {
                $backupProgressPreference = $global:ProgressPreference
                $global:ProgressPreference = 'SilentlyContinue'
            }

            try {
                $resource = "$LocalizedData.Install_DependencyModule_ShouldProcessModuleResource_ModuleName_ModuleVersion" -f ($ModuleName, $ModuleVersion)
                if ($PSCmdlet.ShouldProcess($resource,
                                            "$LocalizedData.Install_DependencyModule_ShouldProcessModuleInstallationOperation")) {
                    $message = "$LocalizedData.Install_DependencyModule_InstallModule_ModificationMessage_ModuleName_ModuleVersion" -f ($ModuleName, $ModuleVersion)
                    Write-Modification -Message $message
                    Install-Module -Name $ModuleName -RequiredVersion $ModuleVersion -Scope CurrentUser -AllowPrerelease -Force -Confirm:$False
                }
            } finally {
                if ($backupProgressPreference) {
                    $global:ProgressPreference = $backupProgressPreference
                }
            }
        }

        if ($moduleToUnload) {
            $resource = "LocalizedData.Install_DependencyModule_ShouldProcessModuleResource_ModuleName_ModuleVersion -f ($moduleToUnload.ModuleName, $moduleToUnload.Version)"
            if ($PSCmdlet.ShouldProcess($resource,
                                        "$LocalizedData.Install_DependencyModule_ShouldProcessModuleInstallationOperation")) {
                $message = "$LocalizedData.Install_DependencyModule_RemoveModule_ModificationMessage_ModuleName -f $ModuleName"
                Write-Modification -Message $message
                Remove-Module $moduleToUnload -Confirm:$False -Force
            }
        }

        Import-Module -FullyQualifiedName @{ ModuleName=$ModuleName; ModuleVersion=$ModuleVersion }
    }
}
