# Write-Message

Writes a specified message string to the information stream with optional preamble and ANSI color escape sequence.

```Write-Message [[-Message] <String[]>] [-Preamble <String>] [-Color {Black | DarkBlue | DarkGreen | DarkCyan | DarkRed | DarkMagenta | DarkYellow | Gray | DarkGray | Blue | Green | Cyan | Red | Magenta | Yellow | White}]```

## Description

Write-Message cmdlet writes a message to the information stream. An optional preamble is also written on the first line before the actual message. Caller may also specify a color of the message using one of the [System.ConsoleColor] members.

## Examples

### Example 1:

```PS >  Write-Message -Message "Working on updates..." -Preamble "{step:updates}" -Color "Red"```

Writes an information in red color perpended with a preamble.

### Example 2:

```PS >  Write-Message -Message "Working on updates..."```

Writes an information in default foreground color with no preamble.

## Parameters

### ```-Message```

*Message to be written by the host.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td>@()</td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Preamble```

*Additional control text to be used for the message.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Color```

*Color for the message.*

<table>
  <tr><td>Type:</td><td>ConsoleColor</td></tr>
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

## Notes

Preamble may be used to decorate a message with a text consumed by the presentation layer. This feature is used by Travis CI for log folding.
