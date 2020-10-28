# Arguments

Arguments for the build toolset commands may be provided by three different means. Following list presents them in order of importance:
1. Command line arguments specified during buildstrapper invocation.
1. Values stored in [Repository Configuration File](RepositoryConfigurationFile.md) file located in the repository root directory provided via Set-CommandArgumentSet cmdlet or on of its subdirectories.
1. Environment variables.

There are four patterns for parameter name matching. Following list presents them in order of precedence:
1. `LeetABitBuild_{ExtensionName}_{ParameterName}`
1. `LeetABitBuild_{TrimmedExtensionName}_{ParameterName}`
1. `{ExtensionName}_{ParameterName}`
1. `LeetABitBuild_{ParameterName}`
1. `{ParameterName}`

`{ExtensionName}` is the name of the extension for which the build command is defined with all dots removed. `{TrimmedExtensionName}` is an `{ExtensionName}` with a `"LeetABitBuild"` prefix removed if present. Patterns with extension name may be used to override more general value specified only by `{ParameterName}` just for one extension. `LeetABit.Build_` prefix gives one more level of specificity to avoid situation where environment variable name in form `{ExtensionName}_{ParameterName}` is already defined in the system and is used by different tools.

## Example

Lets review the following example to better understand how argument discovery mechanism works:

Repository is located in ~/repository directory. It has LeetABit.Build.json file in .build subdirectory.
Content of the LeetABit.Build.json file is following:

```json
{
    "$schema": "https://raw.githubusercontent.com/LeetABit/Build/master/schema/LeetABit.Build.schema.json",
    "ToolsetVersion": "0.0.2",
    "CompilerFlags": "optimize"
}
```

Project located in the repository is supported by the extension module named 'SuperFancy.Extension'. This extension has a command named 'compile' with the following parameters:
`-CompilerFlags <String> -CompilerVersion <String> [-Architecture <x86|x64>] [-Debug]`

Current system has only one version of the SuperFancy compiler installed - 1.0.0. Because of that there is a environment variable defined in the system that specified the available version: `LeetABitBuild_SuperFancyExtension_CompilerVersion = 1.0.0`
In such environment compilation of the repository project may be performed by the following command:

```PS> run.ps1 compile -SuperFancyExtension_Debug```

This invocation will trigger the following argument selection logic:
Compile command parameter set has tree parameters: `CompilerFlags`, `CompilerVersion`, `Architecture` and `Debug`. Argument resolution for the parameters is following:

`CompilerFlags` is not specified in command line but is stored in 'LeetABit.Build.json' file. This parameter gets assigned with value from this file: `"optimize"`.

`CompilerVersion` is not specified in command line nor in 'LeetABit.Build.json' file but environment variable with a matching name in a form `LeetABitBuild_{ExtensionName}_{ParameterName}` is found. This parameter gets assigned with value from environment variables `"1.0.0"`.

`Architecture` is not specified in command line nor in 'LeetABit.Build.json' neither in environment variable. No value has been found but this parameter is optional.

`Debug` is a switch that is specified in command line in a form `{ExtensionName}_{ParameterName}`. A value for this parameter gets assigned with value `$True`.

Finally the command is invoked with the following arguments:

```-CompilerFlags "optimize" -CompilerVersion "1.0.0" -Debug```
