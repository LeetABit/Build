#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

$script:Regex_ScriptBlockSyntax_FunctionName = '(?<={0})(.+?)(?=\[(-WhatIf|-Confirm|\<CommonParameters\>))'
Set-Variable "LeetABitBuildWellKnownParameterNames" -Scope Script -Option ReadOnly -Value (
    'ArtifactsRoot', 'SourceRoot', 'TestRoot', 'ReferenceDocsRoot', 'ExtensionModule', 'ResolutionRoot', 'ProjectPath', 'TaskName'
)

$script:moduleMetadata = Read-ModuleMetadata $MyInvocation
if ($script:moduleMetadata.Resources) {
    Import-LocalizedData -BindingVariable 'LocalizedData' -FileName $script:moduleMetadata.Resources.Name
}

$script:moduleMetadata.ScriptFiles | ForEach-Object { . $_ }
Export-ModuleMember -Function $script:moduleMetadata.PublicFunctionNames

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    if (Get-Module 'LeetABit.Build.Extensibility') {
        LeetABit.Build.Extensibility\Unregister-BuildExtension "LeetABit.Build.Help" -ErrorAction SilentlyContinue
    }
}

Register-BuildTask "help" -Jobs (Get-Item function:Write-BuildHelp)
