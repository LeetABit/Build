# Get-BuildHelp

Gets help about build scripts usage.

```Get-BuildHelp [[-ExtensionTopic] <String>] [[-TaskTopic] <String>]```

## Description

Get-BuildHelp cmdlet provides a concise documentation about each of the loaded extensions and build tasks.

## Examples

### Example 1:

```PC> Get-BuildHelp```

Gets help about all registered build extensions and tasks.

### Example 2:

```PC> Get-BuildHelp -ExtensionTopic "PowerShell"```

Gets a detailed help about all tasks provided by "PowerShell" extension.

### Example 3:

```PC> Get-BuildHelp -TaskTopic "build"```

Gets a detailed help about all build commands provided by different extensions.

### Example 4:

```PC> Get-BuildHelp -ExtensionTopic "PowerShell" -TaskTopic "build"```

Gets a detailed help about "build" task provided by "PowerShell" extension.

## Parameters

### ```-ExtensionTopic```

*Optional name of the build extension for which help shall be obtained.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-TaskTopic```

*Optional name of the build task for which help shall be obtained.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input

None

## Output

None
