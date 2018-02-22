#!/usr/bin/env pwsh
#requires -version 6

<#
.SYNOPSIS
Buildstrapper script for passing local Leet.Build tools feed to the buildstrapper.

.DESCRIPTION
This buildstrapper is responsible for configuring local Leet.Build feed for general buildstrapper.

.PARAMETER Arguments
Arguments to be passed to the buildstreapper.
#>
[CmdletBinding(PositionalBinding = $False)]
param( [Parameter(ValueFromRemainingArguments = $True)]
       [String[]] $Arguments
)

Set-StrictMode -Version 2

$ErrorActionPreference   = 'Stop'
$WarningPreference       = 'Continue'

$buildstrapperPath = $PSScriptRoot
('src', 'Leet.Buildstrapper', 'run.ps1') | ForEach-Object { $buildstrapperPath = Join-Path $buildstrapperPath $_ }
Invoke-Expression "& '$buildstrapperPath' -RepositoryRoot $PSScriptRoot -LeetBuildFeed $PSScriptRoot -ForceInstallLeetBuild @Arguments"
