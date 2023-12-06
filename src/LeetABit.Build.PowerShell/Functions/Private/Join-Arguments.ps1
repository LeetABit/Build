#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Join-Arguments ([OrderedDictionary] $arguments) {
    $firstArgumentAdded = $False
    $result = ''
    foreach ($parameterName in $arguments.Keys) {
        if ($firstArgumentAdded) { $result += "; " }
        $result += "$parameterName = '$($arguments[$parameterName])'"
        $firstArgumentAdded = $True
    }

    return $result
}
