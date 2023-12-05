#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Get-GitReleaseNotes {
    param(
        [String]
        $TagPattern = "()"
    )

    process {
        $TagPattern = $TagPattern -replace '\(\)', '([0-9]+)\.([0-9]+)\.([0-9]+)'
        $result = @()
        $commits = git rev-list HEAD
        $recent = $null

        foreach ($commit in $commits) {
            $tagName = Invoke-Expression "git describe --tags --abbrev=0 $commit --always"
            $version = if ($tagName -match $TagPattern) {
                $tagName
            } else {
                $version
            }

            $date = Invoke-Expression "git show -s --format=%cd --date=short $commit"
            $message = Invoke-Expression "git show -s --format=%s $commit"

            if (-not $recent -or -not $recent.ContainsKey('version') -or $recent.version -ne $version) {
                $recent = @{
                    version = $version
                    date = $date
                    message = @()
                }

                $result += $recent
            }

            $recent.message += $message
        }

        $result | ForEach-Object {
            "# $($_.version) - $($_.date)"
            ""
            $_.message | ForEach-Object {
                "    $_"
            }
            ""
        }
    }
}
