#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections
using module LeetABit.Build.Common

Set-StrictMode -Version 3.0

$script:moduleMetadata = Read-ModuleMetadata $MyInvocation
if ($script:moduleMetadata.Resources) {
    Import-LocalizedData -BindingVariable 'LocalizedData' -FileName $script:moduleMetadata.Resources.Name
}

$script:moduleMetadata.ScriptFiles | ForEach-Object { . $_ }
Export-ModuleMember -Function $script:moduleMetadata.PublicFunctionNames

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    if (Get-Module 'LeetABit.Build.Extensibility') {
        LeetABit.Build.Extensibility\Unregister-BuildExtension "LeetABit.Build.Git" -ErrorAction SilentlyContinue
    }
}


# Register-BuildExtension -ExtensionName "LeetABit.Build.Git" -BuildInitializer {
#     param(
#         [String]
#         $SourceRoot
#     )

#     process {
#         # ? current task name?

#         $version = Get-GitSemVer -Version1 -NoPreRelease
#         $prereleaseVersion = (Get-GitSemVer -Version1).Substring($version.Length)
#         $releaseNotes = Get-GitReleaseNotes
#         LeetABit.Build.Arguments\Add-CommandArgument -ParameterName 'LeetABit_Version' -ParameterValue $version
#         LeetABit.Build.Arguments\Add-CommandArgument -ParameterName 'LeetABit_PrereleaseVersion' -ParameterValue $prereleaseVersion
#         LeetABit.Build.Arguments\Add-CommandArgument -ParameterName 'LeetABit_ReleaseNotes' -ParameterValue $releaseNotes
#     }
# }
