@{  RootModule        = 'Leet.Build.Common.psm1'
    ModuleVersion     = '0.0.0'
    GUID              = 'c746fb6e-2397-4956-b0dd-711610d37361'
    Author            = 'Hubert Bukowski'
    CompanyName       = 'Leet'
    Copyright         = 'Copyright (c) Leet. All rights reserved.'
    Description       = 'Provides functionality common to all Leet.Build modyules.'
    PowerShellVersion = '6.0'
    NestedModules     = @('Leet.Build.Logging')
    FunctionsToExport = @('Join-Paths',
                          'Get-SubstringLinewise',
                          'Get-BaseScriptName')
    VariablesToExport = @()
    CmdletsToExport   = @()
    AliasesToExport   = @()
}
