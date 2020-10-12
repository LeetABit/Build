# Unregister-BuildTask
Unregisters specified build task.

```Unregister-BuildTask [-ExtensionName] <String> [[-TaskName] <String[]>] [-IgnoreMissing] [-WhatIf] [-Confirm]```

## Description

Unregister-BuildTask cmdlet tries to unregister specified tasks from the specified extension. If the specified extension or task is not registered this cmdlet behaves according to -IgnoreMissing switch.

## Examples
### Example 1:
```PS> Unregister-BuildTask "PowerShell"```

Tries to unregister all tasks from "PowerShell" extension and emits an error if the extension is not registered yet.

### Example 2:
```PS> Unregister-BuildTask "PowerShell" -TaskName "help" -IgnoreMissing```

Tries to unregister "help" task from "PowerShell" extension and continues execution if the extension nor task is not registered yet.

## Parameters
### ```-ExtensionName```

*Name of the extension for which the build task shall be unregistered.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-TaskName```

*Name of the tasks that shall be unregistered.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-IgnoreMissing```

*Indicates that this cmdlet ignores tasks that are not defined for the specified build extension.*

<table>
  <tr><td>Type:</td><td>SwitchParameter</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td>False</td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
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
