@{  RootModule        = 'Leet.Build.Logging.psm1'
    ModuleVersion     = '0.0.0'
    GUID              = '42d1c1ff-b5b6-40b9-bef3-8795cccce38d'
    Author            = 'Hubert Bukowski'
    CompanyName       = 'Leet'
    Copyright         = 'Copyright (c) Leet. All rights reserved.'
    Description       = 'Provides logging functionality for all Leet.Build modules.'
    PowerShellVersion = '6.0'
    NestedModules     = @()
    FunctionsToExport = @('Write-Step'
                          'Write-Success'
                          'Write-Modification'
                          'Write-Invocation',
                          'Write-Message',
                          'Write-Diagnostics')
    AliasesToExport   = @()
    VariablesToExport = @()
    CmdletsToExport   = @()
}
