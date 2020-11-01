# Write-Diagnostic

Writes a diagnostic message that informs about less relevant script progress.

```Write-Diagnostic [-Message] <String[]>```

## Description

Write-Diagnostic cmdlet writes a less relevant diagnostic build message to the information stream.

## Examples

### Example 1:

```PS >  Write-Diagnostic "Checking optional features finished."```

Writes a diagnostic message to the information stream.

## Parameters

### ```-Message```

*Diagnostic message to be written by the host.*

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
