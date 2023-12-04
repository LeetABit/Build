#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Diagnostics.CodeAnalysis
using module LeetABit.Build.Common

Set-StrictMode -Version 3

$script:ConfigurationJson   = $Null
$script:NamedArguments      = @{}
$script:PositionalArguments = @()
[ArrayList]$script:UnknownArguments = @()

$script:AllParameterSets = '__AllParameterSets'

$script:moduleMetadata = Read-ModuleMetadata $MyInvocation
if ($script:moduleMetadata.Resources) {
    Import-LocalizedData -BindingVariable 'LocalizedData' -FileName $script:moduleMetadata.Resources.Name
}

$script:moduleMetadata.ScriptFiles | ForEach-Object { . $_ }
Export-ModuleMember -Function $script:moduleMetadata.PublicFunctionNames
