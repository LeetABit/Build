@ECHO OFF
REM ==========================================================================
REM   Copyright (c) Hubert Bukowski. All rights reserved.
REM   Licensed under the MIT License.
REM   See License.txt in the project root for full license information.
REM --------------------------------------------------------------------------
REM   Buildstrapper script for passing local LeetABit.Build toolset location
REM   to the general buildstrapper.
REM ==========================================================================

:Init

"%~dp0src\LeetABit.Buildstrapper\run.cmd" -RepositoryRoot "%~dp0." -ToolsetLocation "%~dp0src" %*

:End
