# Get-BuildExtension

Gets information about all registered build extensions.

```Get-BuildExtension [[-Name] <String[]>]```

## Description

Get-BuildExtension cmdlet retrieves an information about all registered build extensions which names contains specified $Name parameter. To register a build extensions use Register-BuildExtension cmdlet.

## Examples

### Example 1:

```PS> Get-BuildExtension -Name "PowerShell"```

Retrieves all registered build extensions that have a "PowerShell" term in its registered name.

## Parameters

### ```-Name```

*Name of the extensions or part of it.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input

None

## Output

```[ExtensionDefinition[]]```

## Related Links

[Register-BuildExtension](Register-BuildExtension.md)
