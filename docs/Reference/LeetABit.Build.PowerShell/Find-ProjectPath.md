# Find-ProjectPath

Finds paths to all script files and PowerShell module directories in the specified path.

```Find-ProjectPath [-Path] <String[]>```

```Find-ProjectPath [-LiteralPath] <String[]>```

## Description

The Find-ProjectPath cmdlet searches for a script or module in the specified location and returns a path to each item found.

## Examples

### Example 1:

```PS > Find-ProjectPath -Path "C:\Modules"```

Returns paths to all scripts and modules located in the specified directory.

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
