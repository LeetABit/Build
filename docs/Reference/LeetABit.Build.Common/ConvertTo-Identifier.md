# ConvertTo-Identifier

Converts a string to an identifier be removing all invalid characters.

```ConvertTo-Identifier [-Value] <String>```

## Description

ConvertTo-Identifier cmdlet creates an identifier from the specified string value by replacing all characters that are not letter, digit or underscore with underscore.
When the value does not start with letter or underscore this cmdlet inserts an underscore character at the beginning of the result.

## Examples

### Example 1:

```PS> ConvertTo-Identifier ""```

Returns an underscore as an identifier created from an empty string.

### Example 2:

```PS> ConvertTo-Identifier "Convert this"```

Returns "Convert_this" string as an identifier created from the input value.

## Parameters

### ```-Value```

*String to convert.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input

None

## Output

```[System.String]```
