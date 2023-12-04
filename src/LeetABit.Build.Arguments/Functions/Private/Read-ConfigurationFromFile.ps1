#requires -version 6

Set-StrictMode -Version 3

function Read-ConfigurationFromFile {
    <#
    .SYNOPSIS
        Initializes a script configuration values from LeetABit.Build.json configuration file.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Location of the repository for which te configuration file shall be located.
        [Parameter(HelpMessage = "Provide path to the repository root directory.",
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [ValidateContainerPathAttribute()]
        [String]
        $RepositoryRoot
    )

    process {
        $result = @{}
        Get-ChildItem -Path $RepositoryRoot -Filter 'LeetABit.Build.json' -Recurse | Foreach-Object {
            $configFilePath = $_.FullName
            Write-Verbose ($LocalizedData.Message_InitializingConfigurationFromFile_FilePath -f $configFilePath)

            if (Test-Path $configFilePath -PathType Leaf) {
                try {
                    $configFileContent = Get-Content -Raw -Encoding UTF8 -Path $configFilePath
                    ConvertFrom-Json $configFileContent | ConvertTo-Hashtable | ForEach-Object {
                        foreach ($key in $_.Keys) {
                            $result[$key] = $_[$key]
                        }
                    }
                }
                catch {
                    throw [System.IO.FileFormatException]::new([Uri]::new($configFilePath), $LocalizedData.Exception_IncorrectJsonFileFormat, $_)
                }
            }
        }

        $result
    }
}
