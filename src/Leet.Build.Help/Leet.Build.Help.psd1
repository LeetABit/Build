@{  RootModule        = 'Leet.Build.Help.psm1'
    ModuleVersion     = '0.0.0'
    GUID              = '93b4f224-c79b-4513-aab6-7c162279eaf9'
    Author            = 'Hubert Bukowski'
    CompanyName       = 'Leet'
    Copyright         = 'Copyright (c) Leet. All rights reserved.'
    Description       = 'Provides dynamic help for available commands.'
    PowerShellVersion = '6.0'
    NestedModules     = @('Leet.Build.Logging',
                          'Leet.Build.Commands',
                          'Leet.Build.Common')
    FunctionsToExport = @('Invoke-OnHelpCommand')
    VariablesToExport = @()
    CmdletsToExport   = @()
    AliasesToExport   = @()
}
