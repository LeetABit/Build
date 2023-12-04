#requires -version 6
using namespace System.Collections

Set-StrictMode -Version 3.0

function Convert-DictionaryToHelpObject {
    <#
    .SYNOPSIS
        Converts a hashtable to a PSObject using keys as property names with associated values.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String])]

    param (
        # A hashtable with desired object's properties.
        [Parameter(Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [IDictionary]
        $Properties,

        # A name of the help object's type that shall be assigned to the object.
        [Parameter(Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $HelpObjectName,

        # A name of the help object's type suffix that shall be assigned to the object as a secondary type.
        [Parameter(Position = 2,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $HelpView
    )

    begin {
        $typeNameNamespace = 'LeetABit.Build.'
    }

    process {
        LeetABit.Build.Common\New-PSObject (($typeNameNamespace + $HelpObjectName + ".$HelpView"), ($typeNameNamespace + $HelpObjectName)) $Properties
    }
}
