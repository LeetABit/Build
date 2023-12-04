#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Diagnostics.CodeAnalysis

Set-StrictMode -Version 3.0

function Resolve-RepositoryRoot {
    <#
    .SYNOPSIS
        Provides a default mechanism of project resolution for build extension.
    .PARAMETER ResolutionRoot
        Path to the project.
    #>

    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String])]

    param (
        [String]
        $ResolutionRoot
    )

    $ResolutionRoot
}
