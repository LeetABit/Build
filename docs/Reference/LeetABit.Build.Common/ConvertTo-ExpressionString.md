# ConvertTo-ExpressionString

Converts an object to a PowerShell expression string with a specified indentation.

```ConvertTo-ExpressionString [-Obj] <Object> [[-IndentationLevel] <Int32>]```

## Description

The ConvertTo-ExpressionString cmdlet converts any .NET object to a object type's defined string representation.
Dictionaries and PSObjects are converted to hash literal expression format. The field and properties are converted to key expressions,
the field and properties values are converted to property values, and the methods are removed. Objects that implements IEnumerable
are converted to array literal expression format.
Each line of the resulting string is indented by the specified number of spaces.

## Examples

### Example 1:

```PS >  ConvertTo-ExpressionString -Obj $Null, $True, $False
$Null
$True
$False```

Converts PowerShell literals expression string.

### Example 2:

```PS >  ConvertTo-ExpressionString -Obj @{Name = "Custom object instance"}
@{
  'Name' = 'Custom object instance'
}```

Converts hashtable to PowerShell hash literal expression string.

### Example 3:

```PS >  ConvertTo-ExpressionString -Obj @( $Name )
@(
  $Null
)```

Converts array to PowerShell array literal expression string.

### Example 4:

```PS >  ConvertTo-ExpressionString -Obj (New-PSObject "SampleType" @{Name = "Custom object instance"})
<# SampleType #`>
@{
  'Name' = 'Custom object instance'
}```

Converts custom PSObject to PowerShell hash literal expression string with a custom type name in the comment block.

## Parameters

### ```-Obj```

*Object to convert.*

<table>
  <tr><td>Type:</td><td>Object</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-IndentationLevel```

*Number of spaces to perpend to each line of the resulting string.*

<table>
  <tr><td>Type:</td><td>Int32</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td>0</td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input

None

## Output

```[System.String[]]```
