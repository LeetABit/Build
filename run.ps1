#!/usr/bin/env pwsh
#requires -version 6

<#
.SYNOPSIS
Buildstrapper script for passing local LeetABit.Build toolset location to the general buildstrapper.

.DESCRIPTION
This buildstrapper is responsible for configuring local LeetABit.Build toolset location to the general buildstrapper.
#>

Set-StrictMode -Version 2

$localToolsetDirectoryPath  = Join-Path $PSScriptRoot               'src'
$buildstrapperDirectoryPath = Join-Path $localToolsetDirectoryPath  'LeetABit.Buildstrapper'
$buildstrapperPath          = Join-Path $buildstrapperDirectoryPath 'run.ps1'

& "$buildstrapperPath" -RepositoryRoot "$PSScriptRoot" -ToolsetLocation "$localToolsetDirectoryPath" @args
