#requires -version 6
using namespace System.Collections

Set-StrictMode -Version 3.0

[Queue]$script:LastStep       = [Queue]::new()
[Queue]$script:LastStepResult = [Queue]::new()

$script:moduleMetadata = Read-ModuleMetadata $MyInvocation
if ($script:moduleMetadata.Resources) {
    Import-LocalizedData -BindingVariable 'LocalizedData' -FileName $script:moduleMetadata.Resources.Name
}

$script:moduleMetadata.ScriptFiles | ForEach-Object { . $_ }
Export-ModuleMember -Function $script:moduleMetadata.PublicFunctionNames

