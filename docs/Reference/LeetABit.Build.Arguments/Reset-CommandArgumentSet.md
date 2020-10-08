# Reset-CommandArgumentSet
Removes all command arguments set in the module command.

```Reset-CommandArgumentSet [-WhatIf] [-Confirm]```

## Description

Reset-CommandArgumentSet cmdlet clears all the module internal state that has been set via any of the previous calls to `Initialize-CommandArgument`, `Add-CommandArgument` and `Set-CommandArgumentSet` cmdlets.

## Examples
### Example 1:
```PS> Reset-CommandArgumentSet```
Removes all arguments stored in the `LeetABit.Build.Arguments` module.

## Parameters
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

## Related Links
[Initialize-CommandArgument](../Initialize-CommandArgument.md)
[Add-CommandArgument](../Add-CommandArgument.md)
[Set-CommandArgumentSet](../Set-CommandArgumentSet.md)
