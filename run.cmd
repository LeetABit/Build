@ECHO OFF
REM ==========================================================================
REM   Copyright (c) Leet. All rights reserved.
REM   Licensed under the MIT License.
REM   See License.txt in the project root for full license information.
REM --------------------------------------------------------------------------
REM   Buildstrapper script for passing local Leet.Build tools feed to the
REM   general buildstrapper.
REM ==========================================================================

:Init

"%~dp0src\Leet.Buildstrapper\run.cmd" -RepositoryRoot "%~dp0\" -LeetBuildFeed "%~dp0\" -SkipDeploymentCheck -SuppressLocalCopy %*

:End
