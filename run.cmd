@ECHO OFF
::##########################################################################
::  Copyright (c) Hubert Bukowski. All rights reserved.
::  Licensed under the MIT License.
::  See License.txt in the project root for full license information.
::##########################################################################

:Init

"%~dp0src\LeetABit.Buildstrapper\run.cmd" -RepositoryRoot "%~dp0." -ToolsetLocation "%~dp0src" %*

:End
