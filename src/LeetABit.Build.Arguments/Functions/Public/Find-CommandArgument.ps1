#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3

function Find-CommandArgument {
    <#
    .SYNOPSIS
        Locates an argument for a specified named parameter.
    .DESCRIPTION
        Find-CommandArgument cmdlet tries to find argument for the specified parameter. The cmdlet is looking for a variable which name matches one of the following case-insensitive patterns: `LeetABitBuild_$ExtensionName_$ParameterName`, `$ExtensionName_$ParameterName`, `LeetABitBuild_$ParameterName`, `{ParameterName}`. Any dots in the name are ignored. There are four different argument sources, listed below in a precedence order:

        1. Dictionary of arguments specified as value for AdditionalArguments parameter.
        2. Arguments provided via Set-CommandArgumentSet and Add-CommandArgument cmdlets.
        3. Values stored in 'LeetABit.Build.json' file located in the repository root directory provided via Set-CommandArgumentSet cmdlet or on of its subdirectories.
        4. Environment variables.
    .EXAMPLE
        PS> Find-CommandArgument "TaskName" "LeetABit.Build" "help" -AdditionalArguments $arguments

        Tries to find a value for a parameter "TaskName" or "LeetABitBuild_TaskName". At the beginning specified arguments dictionary is being checked. If the value is not found the cmdlet checks all the arguments previously specified via `Add-CommandArgument` and `Set-CommandArgumentSet` cmdlets. If there was no value provided for any of the parameters a default value "help" is returned.
    .EXAMPLE
        PS> Find-CommandArgument "ProducePackages" -IsSwitch

        Tries to find a value for a parameter "ProducePackages" and gives a hint that the parameter is a switch which may be specified without providing a value for it via argument list.
    .NOTES
        This cmdlet is using module's internal state that could be modified by `Reset-CommandArgumentSet`, `Add-CommandArgument`, `Set-CommandArgumentSet` cmdlets.
        When an argument is found in the unknown arguments specified by `Set-CommandArgumentSet` cmdlet it is being moved from unknown arguments list to a named arguments collection.
    .LINK
        Reset-CommandArgumentSet
    .LINK
        Add-CommandArgument
    .LINK
        Set-CommandArgumentSet
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

        # Name of the build extension in which the command is defined.
        [Parameter(Position=1,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [String]
        $ExtensionName,

        # Default value that shall be used when no argument with the specified name is found.
        [Parameter(Position=2,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [Object]
        $DefaultValue,

        # Indicates whether the argument shall be threated as a value for [Switch] parameter.
        [Parameter(Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [Switch]
        $IsSwitch,

        # A dictionary that holds an additional arguments to be used as a parameter's value source.
        [Parameter(Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$False)]
        [IDictionary]
        $AdditionalArguments
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $parameterNames = @()
        if ($ExtensionName) {
            $sanitizedExtensionName = "$($ExtensionName.Replace('.', [String]::Empty))"
            $parameterNames += "LeetABitBuild_$sanitizedExtensionName`_$ParameterName"

            if ($sanitizedExtensionName.StartsWith("LeetABitBuild")) {
                $trimmedExtensionName = $sanitizedExtensionName.Substring("LeetABitBuild".Length)
                if ($trimmedExtensionName) {
                    $parameterNames += "LeetABitBuild_$trimmedExtensionName`_$ParameterName"
                }
            }

            $parameterNames += "$sanitizedExtensionName`_$ParameterName"
        }

        $parameterNames += "LeetABitBuild_$ParameterName"
        $parameterNames += $ParameterName

        foreach ($parameterNameToFind in $parameterNames) {
            if ($parameterNameToFind -eq 'ProjectPath') {
                return $script:ProjectPath
            }

            $result = Find-CommandArgumentInDictionary $parameterNameToFind -Dictionary $AdditionalArguments
            if ($result) {
                Convert-ArgumentValue $result -IsSwitch:$IsSwitch
                return
            }

            $result = Find-CommandArgumentInCommandLine $parameterNameToFind -IsSwitch:$IsSwitch
            if ($result) {
                Convert-ArgumentValue $result -IsSwitch:$IsSwitch
                return
            }

            $result = Find-CommandArgumentInConfiguration $parameterNameToFind
            if ($result) {
                Convert-ArgumentValue $result -IsSwitch:$IsSwitch
                return
            }

            $result = Find-CommandArgumentInEnvironment $parameterNameToFind
            if ($result) {
                Convert-ArgumentString $result -IsSwitch:$IsSwitch
                return
            }
        }

        if ($DefaultValue) {
            $DefaultValue
        }
    }
}
