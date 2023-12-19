# Test-PathInContainer

Checks whether the specified path is contained by any of the specified containers.

```Test-PathInContainer [-Path] <String[]> [-Container] <String[]>```

```Test-PathInContainer [-LiteralPath] <String[]> [-Container] <String[]>```

## Description

The Test-PathInContainer cmdlet returns a value for each specified path that indicates whether this path is contained by any of the specified containers.

## Examples

### Example 1:

```PS> Test-PathInContainer -Path ("C:\Windows\system32", "D:\Repository\temp.file") -Container "C:\Windows"
True
False```

Tests two paths for containment in the specified directory.

## Parameters

### ```-Path```

*The path which shall be checked.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-LiteralPath```

*The path which shall be checked.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Container```

*The path to the container for test.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input

None

## Output

```[System.Boolean]```
