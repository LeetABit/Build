@{  RootModule        = 'Leet.Build.Modules.psm1'
    ModuleVersion     = '0.0.0'
    GUID              = 'a9f0ba1a-8770-449c-b568-b8e8a722c012'
    Author            = 'Hubert Bukowski'
    CompanyName       = 'Leet'
    Copyright         = 'Copyright (c) Leet. All rights reserved.'
    Description       = 'Provides import and removal of Leet.Build extension modules.'
    PowerShellVersion = '6.0'
    NestedModules     = @('Leet.Build.Logging')
    FunctionsToExport = @('Import-ModulesFromDirectory',
                          'Remove-ModulesFromDirectory',
                          'Import-ModuleFromManifest',
                          'Remove-ModuleFromManifest')
    VariablesToExport = @()
    CmdletsToExport   = @()
    AliasesToExport   = @()
}
