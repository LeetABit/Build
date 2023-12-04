#requires -version 6
using namespace System.Collections

Set-StrictMode -Version 3.0

$script:moduleMetadata = Read-ModuleMetadata $MyInvocation
if ($script:moduleMetadata.Resources) {
    Import-LocalizedData -BindingVariable 'LocalizedData' -FileName $script:moduleMetadata.Resources.Name
}

$script:moduleMetadata.ScriptFiles | ForEach-Object { . $_ }
Export-ModuleMember -Function $script:moduleMetadata.PublicFunctionNames


Import-LocalizedData -BindingVariable LocalizedData -FileName LeetABit.Build.Help.Resources.psd1

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    if (Get-Module 'LeetABit.Build.Extensibility') {
        LeetABit.Build.Extensibility\Unregister-BuildExtension "LeetABit.Build.Help" -ErrorAction SilentlyContinue
    }
}

$script:Regex_ScriptBlockSyntax_FunctionName = '(?<={0})(.+?)(?=\[(-WhatIf|-Confirm|\<CommonParameters\>))'


Register-BuildTask "help" -Jobs {
    <#
    .SYNOPSIS
        Gets help for the build script or one of its targets.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Optional name of the build extension for which help shall be obtained.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $ExtensionTopic,

        # Optional name of the build task for which help shall be obtained.
        [Parameter(Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $TaskTopic
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        Get-BuildHelp $ExtensionTopic $TaskTopic | Out-String | Write-Information -InformationAction Continue
    }
}
