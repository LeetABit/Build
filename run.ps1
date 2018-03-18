#!/usr/bin/env pwsh
#requires -version 6
using namespace System.Management.Automation.Language

<#
.SYNOPSIS
Buildstrapper script for passing local Leet.Build tools feed to the buildstrapper.

.DESCRIPTION
This buildstrapper is responsible for configuring local Leet.Build feed for general buildstrapper.
#>

Set-StrictMode -Version 2

$ErrorActionPreference   = 'Stop'
$WarningPreference       = 'Continue'

$buildstrapperPath = $PSScriptRoot
('src', 'Leet.Buildstrapper', 'run.ps1') | ForEach-Object { $buildstrapperPath = Join-Path $buildstrapperPath $_ }
$Tokens = $Null
[Parser]::ParseInput($MyInvocation.Line, ([ref]$Tokens), ([ref]$null))
$scriptName = ($Tokens[1]).Text
$index = $MyInvocation.Line.IndexOf($scriptName) + $scriptName.Length
while (($index -lt $MyInvocation.Line.Length) -and (-not [char]::IsWhiteSpace($MyInvocation.Line[$index]))) { ++$index }
$arguments = $MyInvocation.Line.Substring($index)
Invoke-Expression "& '$buildstrapperPath' -RepositoryRoot $PSScriptRoot -LeetBuildFeed $PSScriptRoot -SkipDeploymentCheck -SuppressLocalCopy $arguments"
