# Invoke-BuildTask

Invokes a specified build task on the specified project.

```Invoke-BuildTask [-ExtensionName] <String> [-TaskName] <String[]> [[-ProjectPath] <String[]>] [[-SourceRoot] <String>] [[-ArgumentList] <String[]>] [-WhatIf] [-Confirm]```

## Description

Invoke-BuildTask cmdlet executes a specified extension's task against specified project.

## Examples

### Example 1:

```PS> Invoke-BuildTask "PowerShell" "test"```

Invokes "test" task from "PowerShell" extension on a repository root directory.

### Example 2:

```PS> Invoke-BuildTask "PowerShell" "test" "~/repository/src/Script.ps1" -ArgumentList @{ "ToolVersion" = "1.0.0" }```

Invokes "test" task from "PowerShell" extension on "~/repository/src/Script.ps1" script file with additional parameter "ToolVersion".

## Parameters

### ```-ExtensionName```

*Name of the extension which defines the task.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-TaskName```

*Name of the tasks to invoke.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-ProjectPath```

*Path to the project on which the task shall invoked.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>3</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-SourceRoot```

*Path to the repository's source directory.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>4</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-ArgumentList```

*Collection with additional arguments that may be used by the task implementation.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>5</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
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

```[System.Object]```
