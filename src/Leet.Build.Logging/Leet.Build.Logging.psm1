#requires -version 6

Set-StrictMode -Version 2

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'Continue'

$EscapeSequence = [char]0x001b + '['

$LightPrefix = if ($env:APPVEYOR) { '1;9' } else { '1;3' }
$DarkPrefix  = '3'

$BlackColor   = '0m'
$RedColor     = '1m'
$GreenColor   = '2m'
$YellowColor  = '3m'
$BlueColor    = '4m'
$MagentaColor = '5m'
$CyanColor    = '6m'
$WhiteColor   = '7m'
$ResetColor   = '0m'

$LastStepName       = ""
$LastIsMajor        = ""

<#
.SYNOPSIS
Writes to the host information about the specified invocation.

.PARAMETER Invocation
Invocation which information shall be written.
#>
function Write-Invocation( [System.Management.Automation.InvocationInfo] $Invocation ) {
    Write-Verbose "Executing: '$($Invocation.MyCommand)' with parameters:"
    $Invocation.BoundParameters.Keys | ForEach-Object {
        Write-Verbose "  -$_ = `"$($Invocation.BoundParameters[$_])`""
    }
}

<#
.SYNOPSIS
Writes a specified message string to the shell host with optional indentation and line wraps.

.PARAMETER Preamble
Additional control text to be used for the message.

.PARAMETER Color
Color for the message.

.PARAMETER Message
Message to be written by the host.

.PARAMETER Indentation
Indentation to applay to each line.

.PARAMETER IgnoreBufferWidth
Specifies whether the function shall ignore host buffer width when spliting message.

.PARAMETER DoNotIndentFirstLine
Specifies whether the first line of the message shall be indented by the function.
#>
function Write-Message ( [String]       $Preamble                 ,
                         [String]       $Color                    ,
                         [String]       $Message                  ,
                         [Int]          $Indentation          = 0 ,
                         [Switch]       $IgnoreBufferWidth        ,
                         [Switch]       $DoNotIndentFirstLine     ) {
    if (-not $Message) { Write-Host; return }

    $indentationText     = ' ' * $Indentation

    $limit = if ($IgnoreBufferWidth) { $Message.Length                                         }
             else                    { (get-host).UI.RawUI.BufferSize.Width - $Indentation - 1 }
    
    for ($index = 0; $index -lt $Message.Length; $index += $limit) {
        if (($Message.Length - $index) -lt $limit) { $limit = $Message.Length - $index }
        $messageLine = $Message.Substring($index, $limit)
        if (($index -gt 0) -or (-Not $DoNotIndentFirstLine)) { $messageLine = $indentationText + $messageLine }

        if ($Color) {
            Write-Host $Preamble$EscapeSequence$Color$messageLine$EscapeSequence$ResetColor
        } else {
            Write-Host $Preamble$messageLine
        }
    }
}

<#
.SYNOPSIS
Writes a message that informs about state change in the current system.

.PARAMETER Message
Modification message to be written by the host.
#>
function Write-Modification ( [String] $Message ) {
    Write-Message -Color $script:LightPrefix$script:MagentaColor -Message $Message
}

<#
.SYNOPSIS
Writes a specified build step message string to the host.

.PARAMETER Message
Step information message to be written by the host.

.PARAMETER Major
Determines whether the step is a major one or minor.
#>
function Write-Step ( [String] $StepName ,
                      [String] $Message  ,
                      [Switch] $Major    ) {
    $preamble = if ($env:TRAVIS) { "travis_fold:start:$StepName`r" } else { '' }
    $color    = if ($Major) { "$script:LightPrefix$script:CyanColor" } else { "$script:DarkPrefix$script:CyanColor" }

    Write-Message -Preamble $preamble -Color $color -Message $Message

    $script:LastStepName = $StepName
    $script:LastIsMajor  = $Major
}

<#
.SYNOPSIS
Writes a specified build step success message string to the host.
#>
function Write-Success ( [String] $StepName ,
                         [Switch] $Major    ) {
    $foldName = if ($psboundparameters.ContainsKey("StepName")) { $StepName } else { $script:LastStepName }
    $isMajor  = if ($psboundparameters.ContainsKey("Major"))    { $Major    } else { $script:LastIsMajor  }
  
    $preamble = if ($env:TRAVIS) { "travis_fold:end:$foldName`r" } else { '' }
    $color    = if ($isMajor) { "$script:LightPrefix$script:GreenColor" } else { "$script:DarkPrefix$script:GreenColor" }
    
    Write-Message -Preamble $preamble -Color $color -Message 'Success.'
    Write-Message
}

Export-ModuleMember -Variable '*' -Alias '*' -Function '*' -Cmdlet '*'
