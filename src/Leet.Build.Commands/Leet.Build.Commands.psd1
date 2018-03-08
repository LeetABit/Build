@{  RootModule        = 'Leet.Build.Commands.psm1'
    ModuleVersion     = '0.0.0'
    GUID              = '51fd3eaa-1599-413d-817d-3afc84ee491d'
    Author            = 'Hubert Bukowski'
    CompanyName       = 'Leet'
    Copyright         = 'Copyright (c) Leet. All rights reserved.'
    Description       = 'Provides functionality related to arguments handling.'
    PowerShellVersion = '6.0'
    NestedModules     = @('Leet.Build.Logging',
                          'Leet.Build.Arguments')
    FunctionsToExport = @('Invoke-Command')
    VariablesToExport = @()
    CmdletsToExport   = @()
    AliasesToExport   = @()
}
