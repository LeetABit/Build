#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Unregister-BuildExtension {
    <#
    .SYNOPSIS
        Unregisters specified build extension.
    .DESCRIPTION
        Unregister-BuildExtension removes all registered information for a specified extension name. If the specified extension is not registered this cmdlet behaves according to -IgnoreMissing switch.
    .EXAMPLE
        PS> Unregister-BuildExtension "PowerShell"

        Tries to unregister a "PowerShell" extension and emits an error if the extension is not registered yet.
    .EXAMPLE
        PS> Unregister-BuildExtension ("PowerShell", "Dotnet") -IgnoreMissing

        Tries to unregister a "PowerShell" and "Dotnet" extensions. The command continues execution without error if an extension to be removed is not registered.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = 'Low')]

    [SuppressMessage(
        'PSReviewUnusedParameter',
        'IgnoreMissing',
        Justification = 'False positive as rule does not scan child scopes: https://github.com/PowerShell/PSScriptAnalyzer/issues/1472')]
    param (
        # Name of the extension that shall be unregistered.
        [Parameter(HelpMessage = 'Provide name of the extension that shall be unregistered.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $ExtensionName,

        # Indicates that this cmdlet ignores build extensions that are not registered.
        [SuppressMessageAttribute(
            'PSReviewUnusedParameter',
            'ReplaceWithParameterName',
            Justification = 'False positive as rule does not scan child scopes: https://github.com/PowerShell/PSScriptAnalyzer/issues/1472')]
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [Switch]
        $IgnoreMissing
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $ExtensionName | ForEach-Object {
            if (!$script:Extensions.ContainsKey($_) -and -not $IgnoreMissing) {
                throw $LocalizedData.Error_UnregisterBuildExtension_Reason -f
                    ($LocalizedData.Exception_ExtensionNotFound_ExtensionName -f $_)
            }
        }

        $ExtensionName | ForEach-Object {
            $target = $LocalizedData.BuildExtension_ExtensionName -f $ExtensionName
            $action = $LocalizedData.Unregister
            if ($PSCmdlet.ShouldProcess($target, $action)) {
                $script:Extensions.Remove($_)
            }
        }
    }
}
