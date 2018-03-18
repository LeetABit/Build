#requires -version 6

Set-StrictMode -Version 2

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'Continue'

<#
.SYNOPSIS
Overrides the default 'verify' command procedure.
#>
function Invoke-OnVerifyCommand () {
    return $true
}

Export-ModuleMember -Variable '*' -Alias '*' -Function '*' -Cmdlet '*'
