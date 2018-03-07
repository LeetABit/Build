@{  RootModule        = 'Leet.Build.Arguments.psm1'
    ModuleVersion     = '0.0.0'
    GUID              = '45da436a-547f-4343-a18d-365a34372aa9'
    Author            = 'Hubert Bukowski'
    CompanyName       = 'Leet'
    Copyright         = 'Copyright (c) Leet. All rights reserved.'
    Description       = 'Provides functionality related to arguments handling.'
    PowerShellVersion = '6.0'
    NestedModules     = @('Leet.Build.Logging')
    FunctionsToExport = @('Set-CommandArguments',
                          'Select-Arguments')
    VariablesToExport = @()
    CmdletsToExport   = @()
    AliasesToExport   = @()
}
