#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections.Generic

Set-StrictMode -Version 3.0

function Update-MultilineProperty {
    param (
        [List[String]]
        $lines,

        [String]
        $BeginingPattern,

        [String]
        $EndPattern,

        [String[]]
        $Content
    )

    process {
        if ($Content) {
            $start = $lines.IndexOf($BeginingPattern)
            if ($start -ge 0) {
                $end = $lines.IndexOf($EndPattern, $start)
                if ($end -ge 0) {
                    $lines.RemoveRange($start + 1, $end - $start - 1)
                    $lines.InsertRange($start + 1, $Content)
                }
            }
        }

        $lines
    }
}
