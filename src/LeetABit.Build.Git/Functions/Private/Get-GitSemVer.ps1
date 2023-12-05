#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Get-GitSemVer {
    param(
        [Switch]
        $NoBranch,
        [Switch]
        $NoHash,
        [Switch]
        $NoTimestamp,
        [Switch]
        $NoLocal,
        [Switch]
        $NoPreRelease,
        [Switch]
        $SingleStep,
        [String]
        $TagPattern = "()",
        [String]
        $MajorPattern = "^Breaking:",
        [String]
        $MinorPattern = "^Feature:",
        [Switch]
        $Version1
    )

    process {
        $major = 0
	    $minor = 1
	    $patch = 0

        $lastVersionedCommit = git describe --tags --abbrev=0 --match '?*.?*.?*' --always
        $TagPattern = $TagPattern -replace '\(\)', '([0-9]+)\.([0-9]+)\.([0-9]+)'

        if ($lastVersionedCommit -match $TagPattern) {
            Write-Verbose "Version tag has been found: $lastVersionedCommit."
            $major=$matches[1]
            $minor=$matches[2]
            $patch=$matches[3]
        } else {
            Write-Verbose 'Version tag has not been found.'
            $lastVersionedCommit = git rev-list --max-parents=0 HEAD
        }

        Write-Verbose "Last versioned commit: $lastVersionedCommit"
        $commits = Invoke-Expression "git rev-list $lastVersionedCommit..HEAD --reverse"


        $commits | ForEach-Object {
            $changes = 0
            Write-Verbose "Analyzing commit $_"
            $show = Invoke-Expression "git show -s --format=%s $_"
            if ($show -match $MajorPattern) {
                $changes = 3
            } elseif ($show -match $MinorPattern) {
                if ($changes -lt 2) {
                    $changes = 2
                }
            } else {
                if ($changes -lt 1) {
                    $changes = 1
                }
            }

            if (-not $SingleStep) {
                if ($changes -eq 3) {
                    $major = [int]$major + 1
                    $minor = 0
                    $patch = 0
                } elseif ($changes -eq 2) {
                    $minor = [int]$minor + 1
                    $patch = 0
                } elseif ($changes -eq 1) {
                    $patch = [int]$patch + 1
                }

                $changes = 0
            }
        }

        if ($SingleStep) {
            if ($changes -eq 3) {
                $major = [int]$major + 1
                $minor = 0
                $patch = 0
            } elseif ($changes -eq 2) {
                $minor = [int]$minor + 1
                $patch = 0
            } elseif ($changes -eq 1) {
                $patch = [int]$patch + 1
            }
        }

        $result = "$major.$minor.$patch"

        if ($Version1) {
            if (-not $NoPreRelease) {
                $status = git status --porcelain
                if ($status) {
                    $result = "$result-alpha"
                    if ($commits) {
                        $result = "$result$($commits.Length)"
                    }
                } elseif ($commits) {
                    $result = "$result-beta$($commits.Length)"
                }
            }
        } else {
            if (-not $NoPreRelease -and $commits) {
                $result = "$result-beta.$($commits.Length)"
            }

            if (-not $NoLocal) {
                $status = git status --porcelain
                if ($status) {
                    $result = "$result-local"
                }
            }

            if (-not $NoBranch) {
                $result = "$result+Branch.$(git rev-parse --abbrev-ref HEAD)"
            }

            if (-not $NoHash) {
                $result="$result+Hash.$(git rev-parse HEAD)"
            }

            if (-not $NoTimestamp) {
                $result="$result+Timestamp.$(Get-Date -Format 'DyyyyMMddTHHmmss.fffffff')"
            }
        }

        $result
    }
}
