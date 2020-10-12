# Unregister-BuildExtension
Unregisters specified build extension.

```Unregister-BuildExtension [-ExtensionName] <String[]> [-IgnoreMissing] [-WhatIf] [-Confirm]```

## Description

Unregister-BuildExtension removes all registered information for a specified extension name. If the specified extension is not registered this cmdlet behaves according to -IgnoreMissing switch.

## Examples
### Example 1:
```PS> Unregister-BuildExtension "PowerShell"```

Tries to unregister a "PowerShell" extension and emits an error if the extension is not registered yet.

### Example 2:
```PS> Unregister-BuildExtension ("PowerShell", "Dotnet") -IgnoreMissing```

Tries to unregister a "PowerShell" and "Dotnet" extensions. The command continues execution without error if an extension to be removed is not registered.

## Parameters
### ```-ExtensionName```

*Name of the extension that shall be unregistered.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-IgnoreMissing```

*Indicates that this cmdlet ignores build extensions that are not registered.*

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
