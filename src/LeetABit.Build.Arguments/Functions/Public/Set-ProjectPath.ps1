#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3

function Set-ProjectPath {
    <#
    .SYNOPSIS
        Sets path to the currently executing project.
    .PARAMETER ProjectPath
        Argument string to convert.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True)]

    param (
        [Parameter(HelpMessage = 'Provide path to the currently executing project.',
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [String]
        $ProjectPath)

    process {
        if ($PSCmdlet.ShouldProcess($LocalizedData.Resource_ProjectPath,
                                    $LocalizedData.Operation_Set)) {
            $script:ProjectPath = $ProjectPath
        }
    }
}
