#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections

Set-StrictMode -Version 3.0

function New-PSObject {
    <#
    .SYNOPSIS
        Creates an instance of a System.Management.Automation.PSObject object.
    .DESCRIPTION
        The New-PSObject cmdlet creates an instance of a System.Management.Automation.PSObject object.
    .PARAMETER TypeName
        Specifies a custom type name for the object.
    .PARAMETER Property
        Sets property values and invokes methods of the new object.
    .EXAMPLE
        New-PSObject -TypeName "CustomType" -Property @{InstanceName = "Sample instance"}

        Creates a new custom PSObject with custom type [SampleType] and one property "InstanceName" with value equal to Sample instance".
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = "Low")]
    [OutputType([PSObject])]

    param (
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $TypeName,

        [Parameter(Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [IDictionary]
        $Property
    )

    begin {
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if ($PSCmdlet.ShouldProcess($LocalizedData.Resource_PSObject,
                                    $LocalizedData.Operation_New)) {
            $result = New-Object PSObject -Property $Property
            if ($PSBoundParameters.ContainsKey('TypeName') -and $TypeName) {
                foreach ($currentTypeName in $TypeName) {
                    $result.PSObject.TypeNames.Add($currentTypeName)
                }
            }

            $result
        }
    }
}
