# Find-CommandArgument
Locates an argument for a specified named parameter.

```Find-CommandArgument [-ParameterName] <String> [[-ExtensionName] <String>] [[-DefaultValue] <Object>] [-IsSwitch] [-AdditionalArguments <IDictionary>]```

## Description

Find-CommandArgument cmdlet tries to find argument for the specified parameter. The cmdlet is looking for a variable which name matches one of the following case-insensitive patterns: `LeetABitBuild_$ExtensionName_$ParameterName`, `$ExtensionName_$ParameterName`, `LeetABitBuild_$ParameterName`, `{ParameterName}`. Any dots in the name are ignored. There are four different argument sources, listed below in a precedence order:

1. Dictionary of arguments specified as value for AdditionalArguments parameter.
2. Arguments provided via Set-CommandArgumentSet and Add-CommandArgument cmdlets.
3. Values stored in 'LeetABit.Build.json' file located in the repository root directory provided via Set-CommandArgumentSet cmdlet or on of its subdirectories.
4. Environment variables. In addition to the two variable name patterns the cmdlet is looking for environment variable may also be perpended by 'LEETABIT_' prefix.

## Examples
### Example 1:
```PS> Find-CommandArgument "TaskName" "LeetABit.Build" "help" -AdditionalArguments $arguments```

Tries to find a value for a parameter "TaskName" or "LeetABit_Build_TaskName". At the beginning specified arguments dictionary is being checked. If the value is not found the cmdlet checks all the arguments previously specified via Initialize-CommandArgument, Add-CommandArgument and Set-CommandArgumentSet cmdlets. If there was no value provided for any of the parameters a default value "help" is returned.

### Example 2:
```PS> Find-CommandArgument "ProducePackages" -IsSwitch```

Tries to find a value for a parameter "ProducePackages" and gives a hint that the parameter is a switch which may be specified without providing a value for it via argument list.

## Parameters
### ```-ParameterName```

*Name of the parameter.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-ExtensionName```

*Name of the build extension in which the command is defined.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-DefaultValue```

*Default value that shall be used when no argument with the specified name is found.*

<table>
  <tr><td>Type:</td><td>Object</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>3</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-IsSwitch```

*Indicates whether the argument shall be threated as a value for [Switch] parameter.*

<table>
  <tr><td>Type:</td><td>SwitchParameter</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td>False</td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-AdditionalArguments```

*A dictionary that holds an additional arguments to be used as a parameter's value source.*

<table>
  <tr><td>Type:</td><td>IDictionary</td></tr>
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

## Related Links
[Initialize-CommandArgument](Initialize-CommandArgument.md)
[Reset-CommandArgumentSet](Reset-CommandArgumentSet.md)
[Add-CommandArgument](Add-CommandArgument.md)
[Set-CommandArgumentSet](Set-CommandArgumentSet.md)
