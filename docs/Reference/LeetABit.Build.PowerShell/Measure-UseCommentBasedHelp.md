# Measure-UseCommentBasedHelp

Functions and script files should have help comments.

```Measure-UseCommentBasedHelp [-ScriptBlockAst] <ScriptBlockAst>```

## Description

Functions and script files should have a text-based help comments provided to assist users and maintainers in understanding its purpose and behavior.

## Examples

### Example 1:

```PS> Measure-UseCommentBasedHelp -ScriptBlockAst $ScriptBlockAst```

Gets rule violations found in the specified script block.

## Parameters

### ```-ScriptBlockAst```

*Script block's AST to analyze*

<table>
  <tr><td>Type:</td><td>ScriptBlockAst</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input

None

## Output

```[[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]]```
