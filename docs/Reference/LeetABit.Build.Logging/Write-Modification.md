# Write-Modification
Writes a message that informs about state change in the current system.

```Write-Modification [-Message] <String[]>```

## Description

Write-Modification cmdlet writes a message that informs the user about a change that is going to be made to the current system. The message is written to the information stream. This cmdlet shall be used to inform the user about any change that is made to the system in order to give an opportunity to manually revert the changes in case of failure.

## Examples
### Example 1:
```PS >  Write-Modification "Downloading 'archive.zip' file to the repository directory."```

Writes an information message about the file download with the information where it is going to be stored.

## Parameters
### ```-Message```

*Modification message to be written by the host.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input
None

## Output
None
