@{  RootModule        = 'Leet.Build.Extensions.psm1'
    ModuleVersion     = '0.0.0'
    GUID              = '492d90af-a86d-4502-8371-4bee64d1bac0'
    Author            = 'Hubert Bukowski'
    CompanyName       = 'Leet'
    Copyright         = 'Copyright (c) Leet. All rights reserved.'
    Description       = 'Provides access to extension modules defined in the target repository.'
    PowerShellVersion = '6.0'
    NestedModules     = @('Leet.Build.Logging',
                          'Leet.Build.Modules')
    FunctionsToExport = @('Import-ProjectExtensionModules')
    VariablesToExport = @()
    CmdletsToExport   = @()
    AliasesToExport   = @()
}
