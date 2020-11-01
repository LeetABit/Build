#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#
# Manifest file for LeetABit.Build.Arguments module.
#########################################################################################

@{

    # Script module or binary module file associated with this manifest.
    RootModule = 'LeetABit.Build.Arguments.psm1'

    # Version number of this module.
    ModuleVersion = '0.0.2'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID = '45da436a-547f-4343-a18d-365a34372aa9'

    # Author of this module
    Author = 'Hubert Bukowski'

    # Company or vendor of this module
    CompanyName = 'Leet a Bit'

    # Copyright statement for this module
    Copyright = 'Copyright (c) Hubert Bukowski. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Provides functionality related to arguments handling.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '6.0'

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ModuleName = 'LeetABit.Build.Common'; ModuleVersion = '0.0.2'; },
        @{ModuleName = 'LeetABit.Build.Logging'; ModuleVersion = '0.0.2'; }
    )

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @('Add-CommandArgument',
                          'Find-CommandArgument',
                          'Reset-CommandArgumentSet',
                          'Select-CommandArgumentSet',
                          'Set-CommandArgumentSet')

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    FileList = @('LeetABit.Build.Arguments.psm1',
                 'LeetABit.Build.Arguments.Resources.psd1')

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('LeetABit', 'Build', 'Argument')

            # A URL to the license for this module.
            LicenseUri = 'https://raw.githubusercontent.com/LeetABit/Build/master/LICENSE.txt'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/LeetABit/Build'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = @"
- Initial release
"@

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependencies.
            ExternalModuleDependencies = @(
                'LeetABit.Build.Common',
                'LeetABit.Build.Logging'
            )

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}
