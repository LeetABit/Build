#!/usr/bin/env pwsh
#requires -version 6

<#
.SYNOPSIS
Buildstrapper script for passing local Leet.Build tools feed to the buildstrapper.

.DESCRIPTION
This buildstrapper is responsible for configuring local Leet.Build feed for general buildstrapper.
#>

Set-StrictMode -Version 2

$localLeetBuild             = Join-Path $PSScriptRoot               'src'
$buildstrapperDirectoryPath = Join-Path $localLeetBuild             'Leet.Buildstrapper'
$buildstrapperPath          = Join-Path $buildstrapperDirectoryPath 'run.ps1'

& "$buildstrapperPath" -RepositoryRoot "$PSScriptRoot" -LeetBuildLocation "$localLeetBuild" @args
