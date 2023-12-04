#!/usr/bin/env pwsh
#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

<#
.SYNOPSIS
Buildstrapper script for passing local LeetABit.Build toolset location to the general buildstrapper.

.DESCRIPTION
This buildstrapper is responsible for configuring local LeetABit.Build toolset location to the general buildstrapper.
#>

Set-StrictMode -Version 3.0

$buildToolsetDirectoryPath   = Join-Path $PSScriptRoot               'src'
$buildstrapperDirectoryPath  = Join-Path $buildToolsetDirectoryPath  'LeetABit.Buildstrapper'
$buildstrapperPath           = Join-Path $buildstrapperDirectoryPath 'run.ps1'

& "$buildstrapperPath" -RepositoryRoot "$PSScriptRoot" -ToolsetLocation "$buildToolsetDirectoryPath" @args
