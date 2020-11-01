# ConvertTo-NormalizedPath

Converts path to the canonical form that can be used to compare paths.

```ConvertTo-NormalizedPath [-Path] <String[]>```

```ConvertTo-NormalizedPath [-LiteralPath] <String[]>```

## Description

The ConvertTo-NormalizedPath cmdlet converts specified path to canonical form by removing any provider name from the beginning of the path.
In the next steps path is converted to absolute path with unified directory separator characters. This cmdlet does not support wildcard characters.

## Examples

### Example 1:

```PS> ConvertTo-NormalizedPath -LiteralPath '.'```

Returns an absolute path to the current directory.

### Example 2:

```PS> ConvertTo-NormalizedPath -LiteralPath 'C:Windows'```

Returns an absolute path to the Windows subdirectory of the current directory in C drive.

## Parameters

### ```-Path```

*Path to normalize.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-LiteralPath```

*Path to normalize.*

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

```[System.String]```
