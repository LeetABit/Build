# Write-Step
Writes a specified build step message to the information stream with step name folding when run in Travis CI environment.

```Write-Step [-StepName] <String> [-Message] <String[]>```

## Description

Write-Step cmdlet writes a message about a new build step that is about to be started. The message is written to the information stream. This cmdlet also emits a log folding preamble when run in Travis CI environment.

## Examples
### Example 1:
```PS >  Write-Step -StepName "prerequisites" -Message "Installing prerequisites."```

Writes an information message about the build step with a folding preamble when run in Travis CI environment.

## Parameters
### ```-StepName```

*Name of the step that shall be written as a message preamble.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Message```

*Step information message to be written by the host.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input
None

## Output
None

## Related Links
[Write-StepFinished](../Write-StepFinished.md)
