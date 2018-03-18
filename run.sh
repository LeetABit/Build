#!/usr/bin/env bash
#==========================================================================
#  Copyright (c) Leet. All rights reserved.
#  Licensed under the MIT License.
#  See License.txt in the project root for full license information.
#--------------------------------------------------------------------------
#  Buildstrapper script for passing local Leet.Build tools feed to the
#  general buildstrapper.
#==========================================================================

current_folder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
"$current_folder/src/Leet.Buildstrapper/run.sh" -RepositoryRoot "$current_folder" -LeetBuildFeed "$current_folder" -SkipDeploymentCheck -SuppressLocalCopy "$@"
