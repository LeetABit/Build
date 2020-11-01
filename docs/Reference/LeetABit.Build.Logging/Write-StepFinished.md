# Write-StepFinished

Writes a message about the result of the most recent build step and closes folding when run in Travis CI environment.

```Write-StepFinished```

## Description

Write-StepFinished cmdlet writes a message about build step failure when Write-Failure cmdlet was called since last Write-Step. Otherwise a success message is being written to the information stream.

## Examples

### Example 1:

```PS >  Write-StepFinished```

Writes an information about most recent build step result.

## Parameters

## Input

None

## Output

None

## Related Links

[Write-Step](Write-Step.md)

[Write-Failure](Write-Failure.md)
