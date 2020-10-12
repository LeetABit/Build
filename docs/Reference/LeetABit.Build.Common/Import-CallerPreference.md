# Import-CallerPreference
Fetches "Preference" variable values from the caller's scope.

```Import-CallerPreference [-Cmdlet] <PSCmdlet> [-SessionState] <SessionState>```

## Description

Script module functions do not automatically inherit their caller's variables, but they can be
obtained through the $PSCmdlet variable in Advanced Functions. This function is a helper function
for any script module Advanced Function; by passing in the values of $PSCmdlet and
$ExecutionContext.SessionState, Import-CallerPreference will set the caller's preference variables locally.

## Examples
### Example 1:
```PS >  Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState```
Imports the default PowerShell preference variables from the caller into the local scope.

## Parameters
### ```-Cmdlet```

*The $PSCmdlet object from a script module Advanced Function.*

<table>
  <tr><td>Type:</td><td>PSCmdlet</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-SessionState```

*The $ExecutionContext.SessionState object from a script module Advanced Function.
This is how the Import-CallerPreference function sets variables in its callers' scope,
even if that caller is in a different script module.*

<table>
  <tr><td>Type:</td><td>SessionState</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input
None

## Output
None

## Related Links
[about_Preference_Variables](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables)
