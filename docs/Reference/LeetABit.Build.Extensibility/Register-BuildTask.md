# Register-BuildTask
Registers a specified build task for the specified build extension.

```Register-BuildTask [-TaskName] <String> [-Jobs] <Object[]> [-ExtensionName <String>] [-IsDefault] [-Condition <Object>] [-PassThru] [-Force]```

## Description

Register-BuildTask cmdlet registers specified information about build task for the specified extension. Name of the extension for which the registration is being performed may be inferred from the script block which is a part of task jobs. If no extension name is provided and cmdlet cannot infer it from job script block an error is emitted.

## Examples
### Example 1:
```PS> Register-BuildTask "build" ("generate", "compile", "test") -ExtensionName "PowerShell"```

Registers a build task for "build" command that is realized by executing a sequence of the specified tasks. The registration is performed for "PowerShell" extension.

### Example 2:
```PS> Register-BuildTask "generate" ({ param ($RepositoryRoot) begin { New-Resources $RepositoryRoot } })```

Registers a build task for "generate" command that is realized by executing a specified script block. The registration is performed for extension that is named after a module in which the specified script block is defined.

### Example 3:
```PS> Register-BuildTask "test" ("test_scripts", "test_modules") -ExtensionName "PowerShell" -Condition { Text-Command "PSTest" }```

Registers a build task for "test" command that is realized by executing a sequence of "test_scripts" and "test_modules" tasks. The registration is performed for "PowerShell" extension. Execution of the task is conditional on the result of the specified script block execution.

### Example 4:
```PS> Register-BuildTask "test" ("test_scripts", "test_modules") -ExtensionName "PowerShell" -IsDefault```

Registers a build task for "test" command that is realized by executing a sequence of "test_scripts" and "test_modules" tasks. The task is being registered as a default task for the extension - it will be executed when no task nem is specified.

### Example 5:
```PS> Register-BuildTask "test" ("test_scripts", "test_modules") -ExtensionName "PowerShell" -PassThru -Force```

Registers a build task for "test" command that is realized by executing a sequence of "test_scripts" and "test_modules" tasks. The operation returns an information about registered task. The registration is being performed regardless the extension is already registered or not.

## Parameters
### ```-TaskName```

*Name of the task for which the registration shall be performed.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Jobs```

*Defines list of script blocks or names of other tasks that shall be executed in the specified order as a realization of the task being defined.*

<table>
  <tr><td>Type:</td><td>Object[]</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-ExtensionName```

*Name of the extension for which the registration shall be performed.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-IsDefault```

*Marks the task being registered as a task that will be executed when no task name for the execution will be specified.*

<table>
  <tr><td>Type:</td><td>SwitchParameter</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td>False</td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Condition```

*Defines condition that shall be meet to execute the task being defined. This condition may be a script block that will be evaluated during task execution. Parameters for the script block are provided by means of LeetABit.Build.Arguments module. To execute the task the script block need to return a $True value.*

<table>
  <tr><td>Type:</td><td>Object</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td>True</td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-PassThru```

*Returns a information about task defined by the cmdlet. By default, this cmdlet does not generate any output.*

<table>
  <tr><td>Type:</td><td>SwitchParameter</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td>False</td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Force```

*Indicates that this cmdlet overwrites already registered build task.*

<table>
  <tr><td>Type:</td><td>SwitchParameter</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td>False</td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input
None

## Output
```[TaskDefinition]```
