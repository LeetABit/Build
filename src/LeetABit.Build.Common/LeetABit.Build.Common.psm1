#requires -version 6
using namespace System.Management.Automation
using namespace System.Collections
using namespace System.Diagnostics.CodeAnalysis

Set-StrictMode -Version 3.0
Import-LocalizedData -BindingVariable LocalizedData -FileName LeetABit.Build.Common.Resources.psd1


##################################################################################################################
# Public Commands
##################################################################################################################


function ConvertTo-ExpressionString {
    <#
    .SYNOPSIS
        Converts an object to a PowerShell expression string.
    .DESCRIPTION
        The ConvertTo-ExpressionString cmdlet converts any .NET object to a object type's defined string representation.
        Dictionaries and PSObjects are converted to hash literal expression format. The field and properties are converted to key expressions,
        the field and properties values are converted to property values, and the methods are removed. Objects that implements IEnumerable
        are converted to array literal expression format.
    .EXAMPLE
        ConvertTo-ExpressionString -Obj $Null, $True, $False
        $Null
        $True
        $False

        Converts PowerShell literals expression string.
    .EXAMPLE
        ConvertTo-ExpressionString -Obj @{Name = "Custom object instance"}
        @{
          'Name' = 'Custom object instance'
        }

        Converts hashtable to PowerShell hash literal expression string.
    .EXAMPLE
        ConvertTo-ExpressionString -Obj @( $Name )
        @(
          $Null
        )

        Converts array to PowerShell array literal expression string.
    .EXAMPLE
        ConvertTo-ExpressionString -Obj (New-PSObject "SampleType" @{Name = "Custom object instance"})
        <# SampleType #`>
        @{
          'Name' = 'Custom object instance'
        }

        Converts custom PSObject to PowerShell hash literal expression string with a custom type name in the comment block.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String[]])]

    param (
        # Object to convert.
        [Parameter(HelpMessage = 'Provide an object to convert.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [AllowNull()]
        [Object]
        $Obj
    )

    process {
        ConvertTo-ExpressionStringWithIndentation $Obj 0
    }
}


function ConvertTo-Identifier {
    <#
    .SYNOPSIS
        Converts a string to an identifier be removing all invalid characters.
    .DESCRIPTION
        ConvertTo-Identifier cmdlet creates an identifier from the specified string value by replacing all characters that are not letter, digit or underscore with underscore.
        When the value does not start with letter or underscore this cmdlet inserts an underscore character at the beginning of the result.
    .EXAMPLE
        PS> ConvertTo-Identifier ""

        Returns an underscore as an identifier created from an empty string.
    .EXAMPLE
        PS> ConvertTo-Identifier "Convert this"

        Returns "Convert_this" string as an identifier created from the input value.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String])]

    param (
        # String to convert.
        [Parameter(HelpMessage = 'Provide a string to convert.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $Value
    )

    begin {
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if (-not $Value) {
            '_'
            return
        }

        if ($Value[0] -match '"[^a-z_]') {
            $Value = "_$Value"
        }

        $Value -replace '[^a-z0-9_]', '_'
    }
}


function ConvertTo-NormalizedPath {
    <#
    .SYNOPSIS
        Converts path to the canonical form that can be used to compare paths.
    .DESCRIPTION
        The ConvertTo-NormalizedPath cmdlet converts specified path to canonical form by removing any provider name from the beginning of the path.
        In the next steps path is converted to absolute path with unified directory separator characters. This cmdlet does not support wildcard characters.
    .EXAMPLE
        PS> ConvertTo-NormalizedPath -LiteralPath '.'

        Returns an absolute path to the current directory.
    .EXAMPLE
        PS> ConvertTo-NormalizedPath -LiteralPath 'C:Windows'

        Returns an absolute path to the Windows subdirectory of the current directory in C drive.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   DefaultParameterSetName = 'Path')]
    [OutputType([String])]

    param (
        # Path to normalize.
        [Parameter(HelpMessage = 'Provide a path to normalize.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'Path')]
        [String[]]
        $Path,

        # Path to normalize.
        [Parameter(HelpMessage = 'Provide a path to normalize.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'LiteralPath')]
        [String[]]
        $LiteralPath
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            [System.IO.Path]::TrimEndingDirectorySeparator((Convert-Path -Path (Convert-Path -Path $Path)))
        }
        else {
            [System.IO.Path]::TrimEndingDirectorySeparator((Convert-Path -LiteralPath (Convert-Path -LiteralPath $LiteralPath)))
        }
    }
}


function Copy-ItemWithStructure {
    <#
    .SYNOPSIS
        Copies specified item to a destination directory with the base subdirectory structure.
    .DESCRIPTION
        Copy-ItemWithStructure cmdlet copies specified item to the destination location. Copied items are being stored inside a subdirectory structure that reflects structure between source files and source base directory.
    .EXAMPLE
        PS> Copy-ItemWithStructure -SourceBaseDirectory "C:\BaseDirectory" -SourceFiles "Subdirectory\File.txt" -DestinationDirectory "C:\DestinationDirectory"

        Copies source File.txt item to the C:\DestinationDirectory\Subdirectory location.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = 'Medium',
                   DefaultParameterSetName = 'Path')]

    [SuppressMessage(
        'PSReviewUnusedParameter',
        'Destination',
        Justification = 'False positive as rule does not scan child scopes: https://github.com/PowerShell/PSScriptAnalyzer/issues/1472')]
    param (
        # Path to normalize.
        [Parameter(HelpMessage = 'Provide a path to an item to copy.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'Path')]
        [String[]]
        $Path,

        # Path to normalize.
        [Parameter(HelpMessage = 'Provide a path to an item to copy.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'LiteralPath')]
        [String[]]
        $LiteralPath,

        # Path to the base source directory from which the subdirectory evaluation shall begin.
        [Parameter(HelpMessage = 'Provide path to the base source directory from which the subdirectory evaluation shall begin.',
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [ValidateContainerPathAttribute()]
        [String]
        $Base,

        # Path to the destination folder to which the files shall be copied.
        [Parameter(HelpMessage = 'Provide path to the destination directory to which the files with directory structure shall be copied.',
                   Position = 2,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [ValidateNonLeafPathAttribute()]
        [String]
        $Destination)

    begin {
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $SelectedPath = if ($PSCmdlet.ParameterSetName -eq 'Path') { $Path } else { $LiteralPath }
        $parameters = @{ "$($PSCmdlet.ParameterSetName)" = $SelectedPath }
    }

    process {
        Resolve-RelativePath @parameters -Base $Base | ForEach-Object {
            $sourcePath = Join-Path $Base $_
            $destinationPath = Join-Path $Destination $_

            if (Test-Path $destinationPath) {
                Remove-Item $destinationPath -Force -Recurse
            }

            $destinationDirectory = Split-Path $destinationPath -Parent
            if (-not (Test-Path $destinationDirectory -PathType Container)) {
                if (Test-Path $destinationDirectory -PathType Leaf) {
                    if ($PSCmdlet.ShouldProcess($LocalizedData.Copy_ItemWithStructure_File_FilePath -f $destinationDirectory,
                                                $LocalizedData.Copy_ItemWithStructure_Remove)) {
                        Remove-Item $destinationDirectory -Recurse -Force
                    }
                }
                if ($PSCmdlet.ShouldProcess($LocalizedData.Copy_ItemWithStructure_Directory_DirectoryPath -f $destinationDirectory,
                                            $LocalizedData.Copy_ItemWithStructure_Create)) {
                    [void](New-Item -Path $destinationDirectory -ItemType Directory -Force)
                }
            }

            if ($PSCmdlet.ShouldProcess($LocalizedData.Copy_ItemWithStructure_File_FilePath -f $destinationPath,
                                        $LocalizedData.Copy_ItemWithStructure_CopyWithReplace)) {
                Copy-Item -Path $sourcePath -Destination $destinationPath -Force -Recurse
            }
        }
    }
}


function Import-CallerPreference {
    <#
    .SYNOPSIS
        Fetches "Preference" variable values from the caller's scope.
    .DESCRIPTION
        Script module functions do not automatically inherit their caller's variables, but they can be
        obtained through the $PSCmdlet variable in Advanced Functions. This function is a helper function
        for any script module Advanced Function; by passing in the values of $PSCmdlet and
        $ExecutionContext.SessionState, Import-CallerPreference will set the caller's preference variables locally.
    .EXAMPLE
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        Imports the default PowerShell preference variables from the caller into the local scope.
    .LINK
        about_Preference_Variables
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # The $PSCmdlet object from a script module Advanced Function.
        [Parameter(HelpMessage = 'Provide an instance of the $PSCmdlet object.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [PSCmdlet]
        $Cmdlet,

        # The $ExecutionContext.SessionState object from a script module Advanced Function.
        # This is how the Import-CallerPreference function sets variables in its callers' scope,
        # even if that caller is in a different script module.
        [Parameter(HelpMessage = 'Provide an instance of the $ExecutionContext.SessionState object.',
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [SessionState]
        $SessionState
    )

    begin {
        $preferenceVariablesMap = @{
            'ErrorView' = $null
            'FormatEnumerationLimit' = $null
            'InformationPreference' = $null
            'LogCommandHealthEvent' = $null
            'LogCommandLifecycleEvent' = $null
            'LogEngineHealthEvent' = $null
            'LogEngineLifecycleEvent' = $null
            'LogProviderHealthEvent' = $null
            'LogProviderLifecycleEvent' = $null
            'MaximumHistoryCount' = $null
            'OFS' = $null
            'OutputEncoding' = $null
            'ProgressPreference' = $null
            'PSDefaultParameterValues' = $null
            'PSEmailServer' = $null
            'PSModuleAutoLoadingPreference' = $null
            'PSSessionApplicationName' = $null
            'PSSessionConfigurationName' = $null
            'PSSessionOption' = $null
            'Transcript' = $null

            'ConfirmPreference' = 'Confirm'
            'DebugPreference' = 'Debug'
            'ErrorActionPreference' = 'ErrorAction'
            'VerbosePreference' = 'Verbose'
            'WarningPreference' = 'WarningAction'
            'WhatIfPreference' = 'WhatIf'
        }
    }

    process {
        foreach ($variableName in $preferenceVariablesMap.Keys) {
            $parameterName = $preferenceVariablesMap[$variableName]
            if (-not $parameterName `
                -or `
                -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($parameterName)) {
                $variable = $Cmdlet.SessionState.PSVariable.Get($variableName)

                if ($variable)
                {
                    if ($SessionState -eq $ExecutionContext.SessionState)
                    {
                        Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                    }
                    else
                    {
                        $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                    }
                }
            }
        }
    }
}


function New-PSObject {
    <#
    .SYNOPSIS
        Creates an instance of a System.Management.Automation.PSObject object.
    .DESCRIPTION
        The New-PSObject cmdlet creates an instance of a System.Management.Automation.PSObject object.
    .EXAMPLE
        New-PSObject -TypeName "CustomType" -Property @{InstanceName = "Sample instance"}

        Creates a new custom PSObject with custom type [SampleType] and one property "InstanceName" with value equal to Sample instance".
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = "Low")]
    [OutputType([PSObject])]

    param (
        # Specifies a custom type name for the object.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $TypeName,

        # Sets property values and invokes methods of the new object.
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


function Resolve-RelativePath {
    <#
    .SYNOPSIS
        Resolves a specified path as a relative path anchored at a specified base path.
    .DESCRIPTION
        The Resolve-RelativePath cmdlet returns a relative path between a specified path and a base path.
    .EXAMPLE
        PS> Resolve-RelativePath -Path "C:\Directory\Subdirectory\File.txt" -BasePath "C:\Directory\"

        Gets a path that is relative path to the specified item based on the specified base directory. The result is ".\Subdirectory\File.txt".
    #>
    [CmdletBinding(PositionalBinding = $False,
                   DefaultParameterSetName = 'Path')]
    [OutputType([String])]

    param (
        # The path which relative version shall be obtained.
        [Parameter(HelpMessage = "Provide path to convert.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'Path')]
        [String[]]
        $Path,

        # The path which relative version shall be obtained.
        [Parameter(HelpMessage = "Provide path to convert.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'LiteralPath')]
        [String[]]
        $LiteralPath,

        # The base path in which the relative path shall be rooted.
        [Parameter(Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $Base)

    begin {
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $SelectedPath = if ($PSCmdlet.ParameterSetName -eq 'Path') { $Path } else { $LiteralPath }
        $parameters = @{ "$($PSCmdlet.ParameterSetName)" = $SelectedPath }
        $comparison = if ($IsWindows) { [System.StringComparison]::OrdinalIgnoreCase }
                      else { [System.StringComparison]::Ordinal }
    }

    process {
        Push-Location -LiteralPath $Base
        try {
            $normalizedBasePath = ConvertTo-NormalizedPath -LiteralPath (Get-Location)
            $result = Resolve-Path -Relative @parameters
        }
        finally {
            Pop-Location
        }

        foreach ($currentPath in $result) {
            if (-not [System.IO.Path]::IsPathRooted($currentPath)) {
                $currentPath = Join-Path -Path $normalizedBasePath -ChildPath $currentPath
            }

            $currentPath = ConvertTo-NormalizedPath -LiteralPath $currentPath

            $relativePath = ''

            while ($true) {
                if ($currentPath.IndexOf($normalizedBasePath, $comparison) -eq 0) {
                    if ($currentPath.Equals($normalizedBasePath, $comparison)) {
                        $relativePath = $relativePath + '.'
                    }
                    else {
                        $length = $normalizedBasePath.Length
                        if (-not [System.IO.Path]::EndsInDirectorySeparator($normalizedBasePath)) {
                            $length = $length + 1
                        }

                        $relativePath = $relativePath + $currentPath.Substring($length)
                    }

                    break
                }
                else {
                    $relativePath = $relativePath + '..\'
                    $normalizedBasePath = Split-Path -LiteralPath $normalizedBasePath
                }
            }

            $relativePath
        }
    }
}


function Set-DigitalSignature {
    <#
    .SYNOPSIS
        Sets an Authenticode signature for a specified item.
    .DESCRIPTION
        The Set-DigitalSignature cmdlet adds an Authenticode signature to any file that supports Subject Interface Package (SIP). If there is a signature in the file when this cmdlet runs, that signature is removed.
    .EXAMPLE
        PS> Set-DigitalSignature -ArtifactPath "C:\artifact.dll" -Certificate $cert

        Digitally signs the specified file using specified code sign certificate.
    .EXAMPLE
        PS> Set-DigitalSignature -ArtifactPath "C:\artifact.dll" -CertificatePath "cert:\LocalMachine\My\$CertFingerprint" -TimestampServer "http://timeserver.example.com"

        Digitally signs the specified file using certificate located under specified path in the store and adds timestamp to the signature.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = "Low",
                   DefaultParameterSetName = 'CertificatePath')]
    [OutputType([System.Management.Automation.Signature])]

    param (
        # Path to the file that shall be signed.
        [Parameter(HelpMessage = 'Provide path to the file that shall be signed.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $Path,

        # PowerShell Certificate Store path to the Code Sign certificate.
        [Parameter(HelpMessage = 'Provide path to the Code Sign certificate.',
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'CertificatePath')]
        [String]
        $CertificatePath,

        # Code Sign certificate to be used.
        [Parameter(HelpMessage = 'Provide Code Sign certificate.',
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'Certificate')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        # Code Sign Timestamp Server to be used.
        [Parameter(Position = 2,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $TimestampServer)

    begin {
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'CertificatePath') {
            if ($CertificatePath) {
                $Certificate = Get-ChildItem -Path $CertificatePath -CodeSigningCert
            }
        }

        foreach ($filePath in $Path) {
            Write-Diagnostic ($LocalizedData.Signing_FilePath -f (Split-Path $filePath -Leaf))
            if ($PSCmdlet.ShouldProcess($LocalizedData.Resource_AuthenticodeSignature_FilePath -f $filePath,
                                        $LocalizedData.Operation_Set)) {
                $result = Set-AuthenticodeSignature -FilePath $filePath -Certificate $Certificate -TimestampServer $TimestampServer -HashAlgorithm SHA256
                if ($result.Status -ne 'Valid') {
                    Write-Error ($LocalizedData.ErrorSigning_Status_Message -f ($result.Status, $result.StatusMessage))
                }
            }
        }
    }
}


function Test-PathInContainer {
    <#
    .SYNOPSIS
        Checks whether the specified path is contained by any of the specified containers.
    .DESCRIPTION
        The Test-PathInContainer cmdlet returns a value for each specified path that indicates whether this path is contained by any of the specified containers.
    .EXAMPLE
        PS> Test-PathInContainer -Path ("C:\Windows\system32", "D:\Repository\temp.file") -Container "C:\Windows"
        True
        False

        Tests two paths for containment in the specified directory.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   DefaultParameterSetName = 'Path')]
    [OutputType([Boolean])]

    param(
        # The path which shall be checked.
        [Parameter(HelpMessage = "Provide path to test.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'Path')]
        [String[]]
        $Path,

        # The path which shall be checked.
        [Parameter(HelpMessage = "Provide path to test.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'LiteralPath')]
        [String[]]
        $LiteralPath,

        # The path to the container for test.
        [Parameter(HelpMessage = "Provide path to the container.",
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $Container
    )

    begin {
        $SelectedPath = if ($PSCmdlet.ParameterSetName -eq 'Path') { $Path } else { $LiteralPath }
    }

    process {
        foreach ($currentPath in $SelectedPath) {
            foreach ($containerPath in $Container) {
                $normalizedPath = ConvertTo-NormalizedPath $currentPath
                $normalizedContainerPath = ConvertTo-NormalizedPath $containerPath

                if ($normalizedPath -eq $normalizedContainerPath -or $normalizedPath.StartsWith($normalizedContainerPath + [System.IO.Path]::DirectorySeparatorChar)) {
                    $True
                    break
                }
            }

            $False
        }
    }
}


##################################################################################################################
# Private Commands
##################################################################################################################


function ConvertTo-ExpressionStringWithIndentation {
    <#
    .SYNOPSIS
        Converts an object to a PowerShell expression string with a specified indentation.
    .DESCRIPTION
        The ConvertTo-ExpressionStringWithIndentation cmdlet converts any .NET object to a object type's defined string representation.
        Dictionaries and PSObjects are converted to hash literal expression format. The field and properties are converted to key expressions,
        the field and properties values are converted to property values, and the methods are removed. Objects that implements IEnumerable
        are converted to array literal expression format.
        Each line of the resulting string is indented by the specified number of spaces.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String])]

    param (
        # Object to convert.
        [Parameter(HelpMessage = 'Provide an object to convert.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [Object]
        $Obj,

        # Number of spaces to perpend to each line of the resulting string.
        [Parameter(HelpMessage = 'Provide an indentation level.',
                   Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [ValidateRange([ValidateRangeKind]::NonNegative)]
        [Int32]
        $IndentationLevel = 0
    )

    process {
        $prefix = " " * $IndentationLevel

        if ($Null -eq $Obj) {
            '$Null'
        }
        elseif ($Obj -is [String]) {
            "'$Obj'"
        }
        elseif ($Obj -is [SwitchParameter] -or $Obj -is [Boolean]) {
            "`$$Obj"
        }
        elseif ($Obj -is [IDictionary]) {
            $result = "@{"
            $Obj.Keys | ForEach-Object {
                $value = ConvertTo-ExpressionStringWithIndentation $Obj[$_] ($IndentationLevel + 2)
                $result += [Environment]::NewLine + "$prefix  '$_' = $value; "
            }

            $result = $result.Substring(0, $result.Length - 2)
            $result += [Environment]::NewLine + "$prefix}"
            $result
        }
        elseif ($Obj -is [PSCustomObject]) {
            $result = ""

            if ($Obj.PSObject.TypeNames.Count -gt 0) {
                $result += "<# "
                $Obj.PSObject.TypeNames | ForEach-Object {
                    if ($_ -ne "Selected.System.Management.Automation.PSCustomObject" -and
                        $_ -ne "System.Management.Automation.PSCustomObject" -and
                        $_ -ne "System.Object") {
                        $result += "[$_], "
                    }
                }

                $result = $result.Substring(0, $result.Length - 2)
                $result += " #>"
                $result += [Environment]::NewLine
            }

            $result += "@{"
            Get-Member -InputObject $Obj -MemberType NoteProperty | ForEach-Object {
                $value = $Obj | Select-Object -ExpandProperty $_.Name
                $value = ConvertTo-ExpressionStringWithIndentation $value ($IndentationLevel + 1)
                $result += [Environment]::NewLine + "$prefix  '$($_.Name)' = $value; "
            }

            $result = $result.Substring(0, $result.Length - 2)
            $result += [Environment]::NewLine + "$prefix}"
            $result
        }
        elseif ($Obj -is [IEnumerable]) {
            $result = "("
            $Obj | ForEach-Object {
                $value = ConvertTo-ExpressionStringWithIndentation $_ ($IndentationLevel + 1)
                $result += [Environment]::NewLine + "$prefix  $value, "
            }

            $result = $result.Substring(0, $result.Length - 2)
            $result += [Environment]::NewLine + "$prefix)"
            $result
        }
        else {
            [String]$Obj
        }
    }
}


##################################################################################################################
# Classes
##################################################################################################################


<#
    Validates specified argument as a path to a container.
#>
class ValidateContainerPathAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        $path = [String]$arguments

        if ([String]::IsNullOrWhiteSpace($path)) {
            throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
        }

        [void](Join-Path $path '.')

        if (-not (Test-Path -Path $path -PathType Container)) {
            throw [System.ArgumentException]::new("Argument '$path' is not a valid path to an existing container.")
        }
    }
}


<#
    Validates specified argument as a path to a leaf.
#>
class ValidateLeafPathAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        $path = [String]$arguments

        if ([String]::IsNullOrWhiteSpace($path)) {
            throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
        }

        [void](Join-Path $path '.')

        if (-not (Test-Path -Path $path -PathType Leaf)) {
            throw [System.ArgumentException]::new('Argument is not a valid path to an existing leaf.')
        }
    }
}


<#
    Validates specified argument as a string of consecutive alphanumeric characters.
#>
class ValidateIdentifierAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        if ($arguments -is [String]) {
            $arguments = @($arguments)
        }

        foreach ($argument in $arguments) {
            $identifier = [String]$argument

            if ([String]::IsNullOrWhiteSpace($identifier)) {
                throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
            }

            if ($identifier -notmatch '^[a-z_][a-z0-9_]*$') {
                throw [System.ArgumentException]::new('Specified string was not a correct identifier.')
            }
        }
    }
}


<#
    Validates specified argument as an empty string or string of consecutive alphanumeric characters.
#>
class ValidateIdentifierOrEmptyAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        if ($arguments -is [String]) {
            $arguments = @($arguments)
        }

        foreach ($argument in $arguments) {
            $identifier = [String]$argument

            if ([String]::IsNullOrEmpty($identifier)) {
                return
            }

            if ([String]::IsNullOrWhiteSpace($identifier)) {
                throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
            }

            if ($identifier -notmatch '^[a-z_][a-z0-9_]*$') {
                throw [System.ArgumentException]::new('Specified string was not a correct identifier.')
            }
        }
    }
}


<#
    Validates specified argument as a path to a leaf or not existing entry.
#>
class ValidateNonContainerPathAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        if ($arguments -is [String]) {
            $arguments = @($arguments)
        }

        foreach ($argument in $arguments) {
            $path = [String]$argument

            if ([String]::IsNullOrWhiteSpace($path)) {
                throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
            }

            [void](Join-Path $path '.')

            if (Test-Path -Path $path -PathType Container) {
                throw [System.ArgumentException]::new('Argument cannot be a path to an existing container.')
            }
        }
    }
}


<#
    Validates specified argument as a path to a container or not existing entry.
#>
class ValidateNonLeafPathAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        if ($arguments -is [String]) {
            $arguments = @($arguments)
        }

        foreach ($argument in $arguments) {
            $path = [String]$argument

            if ([String]::IsNullOrWhiteSpace($path)) {
                throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
            }

            [void](Join-Path $path '.')

            if (Test-Path -Path $path -PathType Leaf) {
                throw [System.ArgumentException]::new('Argument cannot be a path to an existing leaf.')
            }
        }
    }
}


<#
    Validates specified argument as a PowerShell path.
#>
class ValidatePathAttribute : ValidateArgumentsAttribute
{
    [void] Validate([object]$arguments, [EngineIntrinsics]$engineIntrinsics)
    {
        if ([Object]::ReferenceEquals($arguments, $Null)) {
            throw [System.ArgumentNullException]::new()
        }

        if ($arguments -is [String]) {
            $arguments = @($arguments)
        }

        foreach ($argument in $arguments) {
            $path = [String]$argument

            if ([String]::IsNullOrWhiteSpace($path)) {
                throw [System.ArgumentException]::new('String cannot be empty nor contains only empty spaces.')
            }

            [void](Join-Path $path '.')
        }
    }
}


Export-ModuleMember -Function '*' -Variable '*' -Alias '*' -Cmdlet '*'
