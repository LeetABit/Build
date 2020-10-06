# run.ps1
Command execution proxy for LeetABit.Build system that performs all the necessary initialization.

```run.ps1 [[-TaskName] <String>] [-ToolsetVersion <String>] [-RepositoryRoot <String>] [-LogFilePath <String>] [-PreservePreferences] [-UnloadModules] [-Arguments <String[]>] [-WhatIf] [-Confirm]```

```run.ps1 [[-TaskName] <String>] -ToolsetLocation <String> [-RepositoryRoot <String>] [-LogFilePath <String>] [-PreservePreferences] [-UnloadModules] [-Arguments <String[]>] [-WhatIf] [-Confirm]```

## Description

This script is responsible for carrying over any build command to the registered modules through LeetABit.Build\Build-Repository cmdlet. To make this possible the script is also responsible for finding and installing required version of the LeetABit.Build modules in the system.
The script may be instructed in two ways:
First one by specifying version of the required LeetABit.Build module. This orders this script to download requested version of LeetABit.Build module from available PSRepositories when it is missing in the system.
Second one by providing path to the directory that contains required LeetABit.Build module files. This path will be added to process $env:PSModulePath variable if not already present there.

## Examples
### Example 1:
```PS > ./run.ps1 help```
Use this command to display available build commands and learn about available parameters when the required LeetABit.Build modules configuration is available in the JSON configuration file or in environmental variable.

### Example 2:
```PS > ./run.ps1 help -ToolsetVersion 1.0.0```
Use this command to display available build commands and learn about available parameters when a specific version of LeetABit.Build module is expected.

### Example 3:
```PS > ./run.ps1 help -ToolsetLocation ~\LeetABit.Build```
Use this command to display available build commands and learn about available parameters for a LeetABit.Build stored in the specified location.

### Example 4:
```PS > ./run.ps1 -TaskName test -RepositoryRoot ~\Repository```
Use this command to execute 'test' command against repository located at ~\Repository location using LeetABit.Build configured in JSON file or via environmental variable.
Configuration LeetABit.Build.json file need to be located under 'build' subfolder of the repository ~\Repository location.

### Example 5:
```PS > ./run.ps1 build -LogFilePath ~\LeetABit.Build.log```
Use this command to execute 'build' command against repository located at current location using LeetABit.Build configured in JSON file or via environmental variable and store execution log in ~\LeetABit.Build.log file.

### Example 6:
```PS > ./run.ps1 build -PreservePreferences```
Use this command to execute 'build' command without modification of PowerShell preference variables.
By default this scripts modifies some of the preference variables bo values better suited for build script, i.e. error shall break execution, etc. All the preference variables are restored after each command execution.

### Example 7:
```PS > ./run.ps1 build -UnloadModules```
Use this command to execute 'build' command and unloads all LeetABit.Build modules from PowerShell before executing the command.

## Parameters
### ```-TaskName```

*Name of the build task to invoke.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-ToolsetVersion```

*Version of the LeetABit.Build tools to use. If not specified the current script will try to read it from 'LeetABit.Build.json' file.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-ToolsetLocation```

*Location of a local LeetABit.Build version to use for the build.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-RepositoryRoot```

*The path to the project's repository root directory. If not specified the current script root directory will be used.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td>$PSScriptRoot</td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-LogFilePath```

*Path to the build log file.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td>LeetABit.Build.log</td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-PreservePreferences```

*Indicates whether the buildstrapper script shall not modify preference variables.*

<table>
  <tr><td>Type:</td><td>SwitchParameter</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td>False</td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-UnloadModules```

*Indicates whether the buildstrapper script shall unload all LeetABit.Build modules before importing them.*

<table>
  <tr><td>Type:</td><td>SwitchParameter</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td>False</td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Arguments```

*Arguments to be passed to the LeetABit.Build toolset.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-WhatIf```

<table>
  <tr><td>Type:</td><td>SwitchParameter</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Confirm```

<table>
  <tr><td>Type:</td><td>SwitchParameter</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input
None

## Output
None

## Notes
Any parameter for LeetABit.Build system may be provided in three ways:
1. Explicitly via PowerShell command arguments.
2. JSON property in 'LeetABit.Build.json' file stored under 'build' subdirectory of the specified repository root.
3. Environmental variable with a 'LeetABit_Build_' prefix before parameter name.

The list above also defines precedence order of the importance.

LeetABit.Build.json configuration file should be a simple JSON object with properties which names match parameter name and which values shall be used as arguments for the parameters.
A JSON schema for the configuration file is available at https://raw.githubusercontent.com/LeetABit/Build/master/schema/LeetABit.Build.schema.json

## Related Links
[LeetABit.Build\Build-Repository](LeetABit.Build/Build-Repository)
