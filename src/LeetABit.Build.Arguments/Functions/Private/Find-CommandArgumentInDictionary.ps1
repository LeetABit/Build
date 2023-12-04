#requires -version 6

Set-StrictMode -Version 3

function Find-CommandArgumentInDictionary {
    <#
    .SYNOPSIS
        Examines specified arguments dictionary for presence of a specified named parameter's value.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([Object])]

    param (
        # Name of the parameter.
        [Parameter(HelpMessage = 'Provide parameter name.',
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [String]
        $ParameterName,

        # A dictionary that holds an arguments to be used as a parameter's value source.
        [Parameter(Position=2,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$False)]
        [IDictionary]
        $Dictionary)

    process {
        if ($Dictionary) {
            foreach ($dictionaryParameterName in $Dictionary.Keys) {
                if ($dictionaryParameterName -ne $ParameterName) {
                    continue
                }

                $Dictionary[$dictionaryParameterName]
                break
            }
        }
    }
}
