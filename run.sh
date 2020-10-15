#!/usr/bin/env bash
#==========================================================================
#  Copyright (c) Hubert Bukowski. All rights reserved.
#  Licensed under the MIT License.
#  See License.txt in the project root for full license information.
#--------------------------------------------------------------------------
#  Buildstrapper script for passing local LeetABit.Build toolset location
#  to the general buildstrapper.
#==========================================================================

current_folder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
"$current_folder/src/LeetABit.Buildstrapper/run.sh" -RepositoryRoot "$current_folder" -ToolsetLocation "$current_folder/src" "$@"
