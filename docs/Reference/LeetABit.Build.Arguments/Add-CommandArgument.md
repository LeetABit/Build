# Add-CommandArgument
Adds a value for the specified parameter.

```Add-CommandArgument [-ParameterName] <String> [-ParameterValue] <String> [-Force]```

## Description

Add-CommandArgument cmdlet stores a specified value for the parameter in internal module state for later usage. This value may be further selected by Find-CommandArgument or Select-CommandArgumentSet cmdlets.

## Examples
### Example 1:
```PS> Add-CommandArgument -ParameterName "TaskName" -ParameterValue "help"```

Checks whether an argument for parameter "TaskName" has been already set. If not the cmdlet assigns a "help" value for it.

### Example 2:
```PS> Add-CommandArgument -ParameterName "TaskName" -ParameterValue "help" -Force```

Sets "help" value for parameter "TaskName" regardless it was already set or not.

## Parameters
### ```-ParameterName```

*Name of the parameter which value shall be updated.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-ParameterValue```

*A new value for the parameter.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Force```

*Indicates that this cmdlet overwrites value already set to the parameter.*

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

## Related Links
[Find-CommandArgument](Find-CommandArgument.md)
[Select-CommandArgumentSet](Select-CommandArgumentSet.md)
