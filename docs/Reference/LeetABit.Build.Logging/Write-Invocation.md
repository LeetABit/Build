# Write-Invocation
Writes a verbose message about the specified invocation.

```Write-Invocation [-Invocation] <InvocationInfo>```

## Description

Write-Invocation cmdlet writes a message to a verbose stream that contains information about executing function invocation.

## Examples
### Example 1:
```PS >  Write-Invocation $MyInvocation```

Writes a verbose information about current function invocation.

## Parameters
### ```-Invocation```

*Invocation which information shall be written.*

<table>
  <tr><td>Type:</td><td>InvocationInfo</td></tr>
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
