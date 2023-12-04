#requires -version 6

Set-StrictMode -Version 3.0

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
