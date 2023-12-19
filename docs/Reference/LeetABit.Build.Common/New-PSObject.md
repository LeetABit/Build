# New-PSObject

Creates an instance of a System.Management.Automation.PSObject object.

```New-PSObject [[-TypeName] <String[]>] [[-Property] <IDictionary>] [-WhatIf] [-Confirm]```

## Description

The New-PSObject cmdlet creates an instance of a System.Management.Automation.PSObject object.

## Examples

### Example 1:

```PS >  New-PSObject -TypeName "CustomType" -Property @{InstanceName = "Sample instance"}```

Creates a new custom PSObject with custom type [SampleType] and one property "InstanceName" with value equal to Sample instance".

## Parameters

### ```-TypeName```

*Specifies a custom type name for the object.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Property```

*Sets property values and invokes methods of the new object.*

<table>
  <tr><td>Type:</td><td>IDictionary</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-WhatIf```

<table>
  <tr><td>Type:</td><td>SwitchParameter</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Confirm```

<table>
  <tr><td>Type:</td><td>SwitchParameter</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input

None

## Output

```[System.Management.Automation.PSObject]```
