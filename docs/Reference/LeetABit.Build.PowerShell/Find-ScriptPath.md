# Find-ScriptPath

Finds paths to all script files in the specified path.

```Find-ScriptPath [-Path] <String[]>```

```Find-ScriptPath [-LiteralPath] <String[]>```

## Description

The Find-ScriptPath cmdlet searches for a script in the specified location and returns a path to each file found.

## Examples

### Example 1:

```PS > Find-ScriptPath -Path "C:\Modules"```

Returns paths to all scripts located in the specified directory.

## Parameters

### ```-Path```

*Path to the search directory.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-LiteralPath```

*Literal path to the search directory.*

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
