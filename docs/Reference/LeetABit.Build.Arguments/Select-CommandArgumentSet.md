# Select-CommandArgumentSet
Selects a collection of arguments that match specified command parameters.

```Select-CommandArgumentSet [-Command] <CommandInfo> [[-ExtensionName] <String>] [[-AdditionalArguments] <IDictionary>]```

```Select-CommandArgumentSet [-ScriptBlock] <ScriptBlock> [[-ExtensionName] <String>] [[-AdditionalArguments] <IDictionary>]```

```Select-CommandArgumentSet [[-ParameterSets] <CommandParameterSetInfo[]>] [[-ExtensionName] <String>] [[-AdditionalArguments] <IDictionary>]```

## Description

Select-CommandArgumentSet cmdlet tries to find parameters for the specified command, script block or parameter collection. The cmdlet is looking for a variables which name matches one of the following case-insensitive patterns: `LeetABitBuild_$ExtensionName_$ParameterName`, `$ExtensionName_$ParameterName`, `LeetABitBuild_$ParameterName`, `{ParameterName}`. Any dots in the name are ignored. There are four different argument sources, listed below in a precedence order:
1. Dictionary of arguments specified as value for AdditionalArguments parameter.
2. Arguments provided via Set-CommandArgumentSet and Add-CommandArgument cmdlets.
3. Values stored in 'LeetABit.Build.json' file located in the repository root directory provided via Set-CommandArgumentSet cmdlet or on of its subdirectories.
4. Environment variables. In addition to the two variable name patterns the cmdlet is looking for environment variable may also be perpended by 'LEETABIT_' prefix.

## Examples
### Example 1:
```PS> Select-CommandArgumentSet -Command (Get-Command LeetABit.Build.PowerShell\Deploy-Project)```

Tries to selects arguments for a Get-Command LeetABit.Build.PowerShell\Deploy-Project command.

### Example 2:
```PS> Select-CommandArgumentSet -ScriptBlock $script -ExtensionName "LeetABit.Build.PowerShell" -AdditionalArguments $arguments```

Tries to selects arguments for a script block defined in "LeetABit.Build.PowerShell" module with an additional arguments specified as a parameter.

### Example 3:
```PS> Select-CommandArgumentSet -ParameterSets (Get-Command LeetABit.Build.PowerShell\Deploy-Project).ParameterSets```

Tries to selects arguments for a Get-Command LeetABit.Build.PowerShell\Deploy-Project command via its parameter sets.

## Parameters
### ```-Command```

*Command for which a matching arguments shall be selected.*

<table>
  <tr><td>Type:</td><td>CommandInfo</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-ScriptBlock```

*Script block for which a matching arguments shall be selected.*

<table>
  <tr><td>Type:</td><td>ScriptBlock</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-ParameterSets```

*Collection of the parameter sets for which a matching arguments shall be selected.*

<table>
  <tr><td>Type:</td><td>CommandParameterSetInfo[]</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-ExtensionName```

*Name of the build extension for which the arguments shall be selected.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-AdditionalArguments```

*Dictionary of additional arguments that shall be used as a source of parameter's values.*

<table>
  <tr><td>Type:</td><td>IDictionary</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>3</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input
None

## Output
```[System.Collections.IDictionary]```
```[System.Object[]]```

## Related Links
[Initialize-CommandArgument](../Initialize-CommandArgument.md)
[Add-CommandArgument](../Add-CommandArgument.md)
[Set-CommandArgumentSet](../Set-CommandArgumentSet.md)
