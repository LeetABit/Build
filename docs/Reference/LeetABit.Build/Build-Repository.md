# Build-Repository

Performs a build operation on all projects located in the specified repository.

```Build-Repository [-RepositoryRoot] <String> [-TaskName] <String[]> [-ExtensionModule <ModuleSpecification[]>] [-NamedArguments <IDictionary>] [-UnknownArguments <String[]>]```

## Description

Build-Repository cmdlet runs project resolution for all registered extensions against specified repository root directory. And then run specified task for all projects and its extensions.

## Examples

### Example 1:

```PS> Build-Repository '~/repository' 'help'```

Runs a help task for all extensions that supports it using no additional arguments.

### Example 2:

```PS> Build-Repository '~/repository' 'build' -ExtensionModule @{ModuleName = "PowerShell"; ModuleVersion = "1.0.0"}```

Loads "PowerShell" extension and runs a build task for all extensions that supports it using no additional arguments.

### Example 3:

```PS> Build-Repository '~/repository' -NamedArguments @{ 'CompilerVersion' = '1.0.0' } -UnknownArguments ("-Debug")```

Runs a default build task for all extensions that supports it using specified additional arguments.

## Parameters

### ```-RepositoryRoot```

*The path to the repository root folder.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-TaskName```

*Name of the build task to invoke.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-ExtensionModule```

*Extension modules to import.*

<table>
  <tr><td>Type:</td><td>ModuleSpecification[]</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-NamedArguments```

*Dictionary of buildstrapper arguments (including dynamic ones) that have been successfully bound.*

<table>
  <tr><td>Type:</td><td>IDictionary</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-UnknownArguments```

*Arguments to be passed to the target.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input

None

## Output

None
