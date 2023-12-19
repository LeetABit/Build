# Resolve-Project

Resolves paths to the projects found in the specified location.

```Resolve-Project [[-Path] <String>] [[-ExtensionName] <String>] [[-TaskName] <String[]>]```

## Description

Resolve-Project cmdlet tries to resolve projects inside specified directory using particular specified extension or all registered extensions.

## Examples

### Example 1:

```PS> Resolve-Project```

Tries to resolve all projects in the source directory inside repository root for all registered extensions.

### Example 2:

```PS> Resolve-Project```

Tries to resolve all projects in the source directory inside repository root for all registered extensions.

### Example 3:

```PS> Resolve-Project -ExtensionName "PowerShell"```

Tries to resolve all projects in the source directory inside repository root for "PowerShell" extension.

### Example 4:

```PS> Resolve-Project -ExtensionName "PowerShell" -TaskName "test"```

Tries to resolve all projects in the source directory inside repository root for "PowerShell" extension only if it supports "test" task.

### Example 5:

```PS> Resolve-Project -TaskName "test"```

Tries to resolve all projects in the source directory inside repository root for all extensions that support "test" task.

### Example 6:

```PS> Resolve-Project -Path "~/repository/source"```

Tries to resolve all projects in the "~/repository/source" directory for all extensions.

## Parameters

### ```-Path```

*Path to location from which the project shall be resolved.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td>(LeetABit.Build.Arguments\Find-CommandArgument 'SourceRoot')</td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-ExtensionName```

*Name of the extension for which the project shall be resolved.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-TaskName```

*Name of the task that the extension shall provide. Extensions that do not support this task are not evaluated during the execution.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>3</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input

None

## Output

```[System.String[]]```
