# Set-CommandArgumentSet

Sets a collection of arguments that shall be used for command execution.

```Set-CommandArgumentSet [-RepositoryRoot] <String> [[-NamedArguments] <IDictionary>] [[-UnknownArguments] <String[]>] [-WhatIf] [-Confirm]```

## Description

Set-CommandArgumentSet cmdlet clears all arguments previously set and stores a new values for the parameters in internal module state for later usage. These values may be further selected by Find-CommandArgument or Select-CommandArgumentSet cmdlets.

## Examples

### Example 1:

```PS> Set-CommandArgumentSet -RepositoryRoot "." -NamedArguments @{ "TaskName" = "help" } -UnknownArguments $args```

Clears all arguments previously set in the module and initializes internal module data with values from the specified parameters.

## Parameters

### ```-RepositoryRoot```

*Location of the repository on which te command will be executed.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-NamedArguments```

*Dictionary of buildstrapper parameters (including dynamic ones) that have been successfully bound.*

<table>
  <tr><td>Type:</td><td>IDictionary</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-UnknownArguments```

*Collection of other arguments passed.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>3</td></tr>
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

This cmdlet searches for repository configuration file called 'LeetABit.Build.json' inside repository root directory. Values from this file are used as one of the arguments source.
This file shall contain one JSON object with properties which names match parameter name and which values shall be used as arguments for these parameters.
A schema for this file is located at https://raw.githubusercontent.com/LeetABit/Build/master/schema/LeetABit.Build.schema.json
