# Resolve-RelativePath

Resolves a specified path as a relative path anchored at a specified base path.

```Resolve-RelativePath [-Path] <String[]> [-Base] <String>```

```Resolve-RelativePath [-LiteralPath] <String[]> [-Base] <String>```

## Description

The Resolve-RelativePath cmdlet returns a relative path between a specified path and a base path.

## Examples

### Example 1:

```PS> Resolve-RelativePath -Path "C:\Directory\Subdirectory\File.txt" -BasePath "C:\Directory\"```

Gets a path that is relative path to the specified item based on the specified base directory. The result is ".\Subdirectory\File.txt".

## Parameters

### ```-Path```

*The path which relative version shall be obtained.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-LiteralPath```

*The path which relative version shall be obtained.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Base```

*The base path in which the relative path shall be rooted.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input

None

## Output

```[System.String]```
