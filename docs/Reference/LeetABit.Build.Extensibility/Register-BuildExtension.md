# Register-BuildExtension

Registers build extension in the module.

```Register-BuildExtension [[-Resolver] <ScriptBlock>] [[-ExtensionName] <String>] [-Force]```

```Register-BuildExtension [-ExtensionName] <String> [-Force]```

## Description

Register-BuildExtension cmdlet stores specified information about LeetABit.Build extension.
Extension may define a project resolver script block. It is used to search for all project
files within the repository that are supported by the extension. Resolver script block may
define parameters. Values for the parameters will be provided by the means of `LeetABit.Build.Arguments` module.
The job of the resolver is to return a path to the project file or directory.
If no resolver is specified a default resolver will be used that returns path to the repository root.

## Examples

### Example 1:

```PS> Register-BuildExtension -ExtensionName "PowerShell"```

Register a default resolver for a "PowerShell" extension if it is not already registered.

### Example 2:

```PS> Register-BuildExtension { "./Project.sln" } -Force```

Tries to evaluate name of the module that called Register-BuildExtension cmdlet and in case of success register a specified resolver for the extension with the name of the evaluated module regardless the extension is already registered or not.

## Parameters

### ```-Resolver```

*ScriptBlock that resolves path to the projects recognized by the specified extension.*

<table>
  <tr><td>Type:</td><td>ScriptBlock</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td>$DefaultResolver</td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-ExtensionName```

*Name of the extension for which the registration shall be performed.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Force```

*Indicates that this cmdlet overwrites already registered extension removing all registered tasks and resolver.*

<table>
  <tr><td>Type:</td><td>SwitchParameter</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td>False</td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input

None

## Output

None

## Notes

When an extension has already registered a resolver of task and a -Force switch is used any registered resolver and all registered tasks are removed during execution of this cmdlet.
