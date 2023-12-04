#requires -version 6

Set-StrictMode -Version 3.0

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Remove-Module LeetABit.Build.* -Force
}

$script:moduleMetadata = Read-ModuleMetadata $MyInvocation
if ($script:moduleMetadata.Resources) {
    Import-LocalizedData -BindingVariable 'LocalizedData' -FileName $script:moduleMetadata.Resources.Name
}

$script:moduleMetadata.ScriptFiles | ForEach-Object { . $_ }
Export-ModuleMember -Function $script:moduleMetadata.PublicFunctionNames
