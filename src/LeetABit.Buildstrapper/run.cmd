@ECHO OFF
::##########################################################################
::  Copyright (c) Hubert Bukowski. All rights reserved.
::  Licensed under the MIT License.
::  See License.txt in the project root for full license information.
::##########################################################################
SETLOCAL EnableDelayedExpansion EnableExtensions


::##########################################################################
::  Configuration.
::##########################################################################
SET "PowerShellVersion=7.4.0"
SET "PowerShellFileName=pwsh.exe"


::##########################################################################
::  Initialization.
::##########################################################################
SET "Architecture=%PROCESSOR_ARCHITECTURE%"
IF "!Architecture!"=="AMD64" SET "Architecture=x64"
IF "!Architecture!"=="ARM" SET "Architecture=ARM32"
SET "PowerShellArchiveFileName=PowerShell-!PowerShellVersion!-win-!Architecture!.zip"

SET "InstallationDirectoryPath=!LOCALAPPDATA!\Microsoft\PowerShell\!PowerShellVersion!"
SET "InstallationPwshPath=!InstallationDirectoryPath!\!PowerShellFileName!"
SET "PowerShellDownloadLink=https://github.com/PowerShell/PowerShell/releases/download/v!PowerShellVersion!/!PowerShellArchiveFileName!"
SET "PowersShellArchiveDestinationPath=!TEMP!\!PowerShellArchiveFileName!"

SET "CurrentFolder=%~dp0"

CALL :InitializeVerboseLogging %*
CALL :InitializeForceInstallPowerShell %*
CALL :InitializeConsoleColors


::##########################################################################
::  Main script procedure.
::##########################################################################
SET "installPowerShell=0"
IF "!ForceInstallPowerShell!"=="1" (
    CALL :WriteVerbose "Forced PowerShell !PowerShellVersion! installation is requested."
    SET "installPowerShell=1"
) ELSE (
    CALL :FindPowerShell !PowerShellVersion! "!PowerShellFileName!" "!InstallationPwshPath!"
    SET "pwshPath=!result!"
    IF "!pwshPath!" EQU "" (
        SET "installPowerShell=1"
        CALL :WriteVerbose "No PowerShell !PowerShellVersion! has been found in the current environment."
    )
)

IF "!installPowerShell!"=="1" (
    CALL :BeginStep "Installing PowerShell Core !PowerShellVersion!..."

    CALL :DownloadFile "!PowerShellDownloadLink!" "!PowersShellArchiveDestinationPath!" || (
        CALL :WriteError "PowerShell archive download failed. Error code: !ERRORLEVEL!"
        EXIT /B 1
    )

    CALL :InstallArchive "!PowersShellArchiveDestinationPath!" "!InstallationDirectoryPath!" || (
        CALL :WriteError "PowerShell archive installation failed. Error code: !ERRORLEVL!"
        EXIT /B 2
    )

    SET "pwshPath=!InstallationPwshPath!"
    CALL :DeleteItem "!PowersShellArchiveDestinationPath!" || (
        CALL :WriteWarning "Could not delete PowerShell archive file. Error code: !ERRORLEVEL!"
    )

    CALL :EndStep
)

IF NOT EXIST "!pwshPath!" (
    CALL :WriteError "Could not find PowerShell executable at '!pwshPath!'."
    EXIT /B 3
)

CALL :ExecuteCommand "!pwshPath!" "!CurrentFolder!run.ps1" %* || (
    CALL :WriteError "PowerShell execution failed. Error code: !ERRORLEVEL!"
    EXIT /B 4
)

EXIT /B 0


::##########################################################################
::  Function definitions.
::##########################################################################

::==========================================================================
::  Checks whether the verbose logging is requested.
::--------------------------------------------------------------------------
::  PARAMETERS:
::      %*
::          All parameters sent to the script.
::--------------------------------------------------------------------------
::  SETS:
::      Verbose
::          Sets to value 1 if verbose logging has been requested;
::          to 0 otherwise.
::==========================================================================
:InitializeVerboseLogging
SETLOCAL EnableDelayedExpansion EnableExtensions

    IF /I "!CI!"=="true" (
        ENDLOCAL & SET "Verbose=1"
        CALL :WriteVerbose "Verbose logging enabled: 'CI' environmental variable with value 'true' found."
        GOTO :EOF
    )

    FOR %%P IN (%*) DO (
        SET "Verbose=0"
        SET "Parameter=%%P"
        IF /I "!Parameter!"=="-Verbose" SET "Verbose=1"
        IF /I "!Parameter!"=="-Verbose:$True" SET "Verbose=1"
        IF /I "!Parameter!"=="-vb" SET "Verbose=1"
        IF /I "!Parameter!"=="-vb:$True" SET "Verbose=1"
        IF /I "!Parameter!"=="-v" SET "Verbose=1"
        IF /I "!Parameter!"=="-v:$True" SET "Verbose=1"

        SET "Argument="

        ECHO !Parameter! | FINDSTR /I /R /C:"^-Verbose:" > NUL
        IF !ERRORLEVEL! == 0 (
            SET "Argument=!Parameter:-Verbose:=!"
        )

        ECHO !Parameter! | FINDSTR /I /R /C:"^-vb:" > NUL
        IF !ERRORLEVEL! == 0 (
            SET "Argument=!Parameter:-vb:=!"
        )

        ECHO !Parameter! | FINDSTR /I /R /C:"^-v:" > NUL
        IF !ERRORLEVEL! == 0 (
            SET "Argument=!Parameter:-v:=!"
        )

        IF "!Argument!" NEQ "" (
            ECHO !Argument! | FINDSTR /I /R /C:"^[0-9]*[1-9][0-9]*\>" > NUL
            IF !ERRORLEVEL! == 0 SET "Verbose=1"
            ECHO !Argument! | FINDSTR /I /R /C:"^0x[0-9a-f]*[1-9a-f][0-9a-f]*\>" > NUL
            IF !ERRORLEVEL! == 0 SET "Verbose=1"
        )

        IF "!Verbose!" == "1" (
            CALL :WriteVerbose "Verbose logging enabled: '!Parameter!' parameter found."
            ENDLOCAL & SET "Verbose=1"
            GOTO :EOF
        )
    )

ENDLOCAL & SET "Verbose=0"
GOTO :EOF


::==========================================================================
::  Checks whether the forced PowerShell installation is requested.
::--------------------------------------------------------------------------
::  PARAMETERS:
::      %*
::          All parameters sent to the script.
::--------------------------------------------------------------------------
::  SETS:
::      ForceInstallPowerShell
::          Sets to value 1 if forced PowerShell installation has been
::          requested; to 0 otherwise.
::==========================================================================
:InitializeForceInstallPowerShell
SETLOCAL EnableDelayedExpansion EnableExtensions

    IF "!LeetABitBuild_ForceInstallPowerShell!"=="1" (
        ENDLOCAL & SET "ForceInstallPowerShell=1"
        CALL :WriteVerbose "Forced PowerShell installation enabled: 'LeetABitBuild_ForceInstallPowerShell' environmental variable with value '1' found."
        GOTO :EOF
    )

    FOR %%P IN (%*) DO (
        SET "ForceInstallPowerShell=0"
        SET "Parameter=%%P"
        IF /I "!Parameter!"=="-ForceInstallPowerShell" SET "ForceInstallPowerShell=1"
        IF /I "!Parameter!"=="-ForceInstallPowerShell:$True" SET "ForceInstallPowerShell=1"

        SET "Argument="

        ECHO !Parameter! | FINDSTR /I /R /C:"^-ForceInstallPowerShell:" > NUL
        IF !ERRORLEVEL! == 0 (
            SET "Argument=!Parameter:-ForceInstallPowerShell:=!"
        )

        IF "!Argument!" NEQ "" (
            ECHO !Argument! | FINDSTR /I /R /C:"^[0-9]*[1-9][0-9]*\>" > NUL
            IF !ERRORLEVEL! == 0 SET "ForceInstallPowerShell=1"
            ECHO !Argument! | FINDSTR /I /R /C:"^0x[0-9a-f]*[1-9a-f][0-9a-f]*\>" > NUL
            IF !ERRORLEVEL! == 0 SET "ForceInstallPowerShell=1"
        )

        IF "!ForceInstallPowerShell!" == "1" (
            CALL :WriteVerbose "Forced PowerShell installation enabled: '!Parameter!' parameter found."
            ENDLOCAL & SET "ForceInstallPowerShell=1"
            GOTO :EOF
        )
    )

ENDLOCAL & SET "ForceInstallPowerShell=0"
GOTO :EOF


::==========================================================================
::  Initializes console colors if the current environment supports colors.
::--------------------------------------------------------------------------
::  SETS:
::      ColorReset
::          Sets to a color reset command if current environment supports
::          colors.
::
::      ColorRed
::          Sets to a red color command if current environment supports
::          colors.
::
::      ColorGreen
::          Sets to a green color command if current environment supports
::          colors.
::
::      ColorYellow
::          Sets to a yellow color command if current environment supports
::          colors.
::
::      ColorMagenta
::          Sets to a magenta color command if current environment supports
::          colors.
::
::      ColorCyan
::          Sets to a cyan color command if current environment supports
::          colors.
::==========================================================================
:InitializeConsoleColors
SETLOCAL EnableDelayedExpansion EnableExtensions

    SET "LightPrefix=1;3"
    SET "ColorReset=[0m"
    SET "ColorRed=[!LightPrefix!1m"
    SET "ColorGreen=[!LightPrefix!2m"
    SET "ColorYellow=[!LightPrefix!3m"
    SET "ColorMagenta=[!LightPrefix!5m"
    SET "ColorCyan=[!LightPrefix!6m"
    SET "ColorsSupported=0"
    SET "Message="

    CALL :GetWindowsVersion
    SET "windowsVersion=!result!"

    SET "MajorVersion="
    SET "ReleaseId="
    FOR /F "tokens=1,5 delims=. " %%A IN ("!windowsVersion!") DO (
        SET "MajorVersion=%%A"
        SET "ReleaseId=%%B"
    )

    IF !MajorVersion! GEQ 10 (
        IF !ReleaseId! GEQ 1511 (
            SET "Message=Console colors enabled: running in Windows v!windowsVersion! environment."
            SET "ColorsSupported=1"
        )
    )

    IF "!ColorsSupported!" == "1" (
        ENDLOCAL & (
            SET "ColorReset=%ColorReset%"
            SET "ColorRed=%ColorRed%"
            SET "ColorGreen=%ColorGreen%"
            SET "ColorYellow=%ColorYellow%"
            SET "ColorMagenta=%ColorMagenta%"
            SET "ColorCyan=%ColorCyan%"
            CALL :WriteVerbose "%Message%"
        )

        GOTO :EOF
    )

ENDLOCAL & (
    CALL :WriteVerbose "Console colors disabled: running in Windows v%windowsVersion% environment."
)
GOTO :EOF


::==========================================================================
::  Searches for the PowerShell executable in the current system.
::--------------------------------------------------------------------------
::  PARAMETERS:
::      %Version%
::          Version of the PowerShell to be found.
::
::      %FileName%
::          Name of the PowerShell executable file.
::
::      %ExpectedPath%
::          Default installation location of the PowerShell executable file.
::--------------------------------------------------------------------------
::  RETURNS:
::      %result%
::          Path to the PowerShell executable file found.
::==========================================================================
:FindPowerShell
SETLOCAL EnableDelayedExpansion EnableExtensions
SET "Version=%1"
SET "FileName=%~2"
SET "ExpectedPath=%~3"

    CALL :WriteVerbose "Searching for '!FileName!' version !Version! in system PATH and at '!ExpectedPath!'..."
    SET "candidates="

    IF NOT EXIST "!ExpectedPath!\*" (
        IF EXIST "!ExpectedPath!" (
            CALL :CheckPowerShellVersion "!ExpectedPath!" "!Version!" && (
                ENDLOCAL & SET "result=%ExpectedPath%" & SET "result=!result:"=!"
                GOTO :EOF
            )
        )
    )

    where /q "!FileName!" > NUL
    IF !ERRORLEVEL! EQU 0 (
        FOR /F "tokens=* delims=;" %%A IN ('where "!FileName!"') DO (
            CALL :CheckPowerShellVersion "%%A" "!Version!" && (
                ENDLOCAL & SET "result=%%A" & SET "result=!result:"=!"
                GOTO :EOF
            )
        )
    )

ENDLOCAL & SET "result="
GOTO :EOF


::==========================================================================
::  Checks whether the PowerShell at specified path has a required version.
::--------------------------------------------------------------------------
::  PARAMETERS:
::      %PowerShellPath%
::          Path to the PowerShell executable file.
::
::      %RequiredVersion%
::          Required PowerShell version.
::==========================================================================
:CheckPowerShellVersion
SETLOCAL EnableDelayedExpansion EnableExtensions
SET "PowerShellPath=%~1"
SET "RequiredVersion=%~2"

    FOR /F "usebackq tokens=2" %%V IN (`"!PowerShellPath!" --version`) DO (
        CALL :WriteVerbose "Found PowerShell %%V at '!PowerShellPath!'."
        IF "%%V"=="!RequiredVersion!" (
            EXIT /B 0
        )
    )

EXIT /B 1

::==========================================================================
::  Downloads a file from the remote location.
::--------------------------------------------------------------------------
::  PARAMETERS:
::      %SourceLocation%
::          Path to the remote file to download.
::
::      %DestinationPath%
::          Path to the destination of the downloaded file.
::==========================================================================
:DownloadFile
SETLOCAL EnableDelayedExpansion EnableExtensions
SET "SourceLocation=%~1"
SET "DestinationPath=%~2"

    CALL :WriteModification "Downloading file from '!SourceLocation!' to '!DestinationPath!'..."

    CALL :ExecuteCommand powershell -command "(new-object System.Net.WebClient).DownloadFile('!SourceLocation!', '!DestinationPath!')" || (
        CALL :WriteError "Could not download file: ExecuteCommand returned error !ERRORLEVEL!."
        CALL :DeleteItem "!DestinationPath!" || (
            write_warning "Could not delete PowerShell archive file. Error code: !ERRORLEVEL!"
        )

        EXIT /B 1
    )

    IF NOT EXIST "!DestinationPath!" (
        CALL :WriteError "Could not download file: destination file does not exist."
        EXIT /B 2
    )

EXIT /B 0


::==========================================================================
::  Installs the specified PowerShell archive file to the specified
::  location.
::--------------------------------------------------------------------------
::  PARAMETERS:
::      %ArchivePath%
::          Path to the archive file to install.
::
::      %DestinationDirectoryPath%
::          Path to the destination directory.
::==========================================================================
:InstallArchive
SETLOCAL EnableDelayedExpansion EnableExtensions
SET "ArchivePath=%~1"
SET "DestinationDirectoryPath=%~2"

    CALL :WriteVerbose "Installing PowerShell at '!DestinationDirectoryPath!'..."

    CALL :DeleteItem "!DestinationDirectoryPath!" || (
        CALL :WriteError "Could not delete old PowerShell destination directory. Error code: '!ERRORLEVEL!'."
        EXIT /B 1
    )

    CALL :WriteModification "Creating directory at '!DestinationDirectoryPath!'..."
    MKDIR "!DestinationDirectoryPath!" || (
        CALL :WriteError "Could not create a directory. Error code: !ERRORLEVEL!"
        EXIT /B 2
    )

    CALL :WriteModification "Expanding archive to '!DestinationDirectoryPath!'..."
    CALL :ExecuteCommand powershell -command "$shell = new-object -com shell.application; $shell.Namespace('!DestinationDirectoryPath!').CopyHere($shell.NameSpace('!ArchivePath!').items(), 4 + 1024)" || (
        CALL :WriteError "Could not expand archive. Error code: !error!"
        EXIT /B 3
    )

EXIT /B 0


::==========================================================================
::  Deletes a file system item specified by its path.
::--------------------------------------------------------------------------
::  PARAMETERS:
::      %ItemPath%
::          Path to the item to delete.
::==========================================================================
:DeleteItem
SETLOCAL EnableDelayedExpansion EnableExtensions
SET "ItemPath=%~1"

    IF EXIST "!ItemPath!\*" (
        CALL :WriteModification "Deleting directory '!ItemPath!'..."
        RMDIR /S /Q "!ItemPath!" > NUL
        EXIT /B !ERRORLEVEL!
    ) ELSE IF EXIST "!ItemPath!" (
        CALL :WriteModification "Deleting file '!ItemPath!'..."
        DEL /F /Q "!ItemPath!" > NUL
        EXIT /B !ERRORLEVEL!
    )

EXIT /B 0


::==========================================================================
::  Executes a specified program with specified arguments and verbose
::  command line logging.
::--------------------------------------------------------------------------
::  PARAMETERS:
::      %*
::          Program path and all the parameters for it.
::==========================================================================
:ExecuteCommand
SETLOCAL EnableDelayedExpansion EnableExtensions

    CALL :WriteVerbose "Executing:"
    CALL :BeginVerbose
    FOR %%P IN (%*) DO CALL :WriteVerboseDirect "%%P "
    CALL :EndVerbose

    %*
    SET "error=!ERRORLEVEL!"

    IF !error! NEQ 0 (
        CALL :WriteError "Command execution failed. Error code: !error!"
        EXIT /B 1
    )

EXIT /B 0


::==========================================================================
::  Gets version of the current Windows operating system.
::--------------------------------------------------------------------------
::  SETS:
::      %result%
::          Version of the current Windows operating system in format:
::          Major.Minor.Build.UpdateBuildRevision ReleaseId
::==========================================================================
:GetWindowsVersion
SETLOCAL EnableDelayedExpansion EnableExtensions

    SET "OSVersion="
    FOR /F "tokens=4-6 delims=][. " %%A IN ('ver') DO (
        SET "OSVersion=%%A.%%B.%%C"
    )

    FOR /F "tokens=3 delims= " %%A IN ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v UBR') DO (
        SET /A "ubr=%%A"
        SET "OSVersion=!OSVersion!.!ubr!"
    )

    FOR /F "tokens=3 delims= " %%A IN ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId 2^> NUL') DO (
        IF !ERRORLEVEL! == 0 (
            SET "OSVersion=!OSVersion! %%A"
        )
    )

ENDLOCAL & SET "result=%OSVersion%"
GOTO :EOF


::==========================================================================
::  Writes a message about a modification about to be done to the current
::  environment.
::--------------------------------------------------------------------------
::  PARAMETERS:
::      Message
::          Modification message.
::==========================================================================
:WriteModification
SETLOCAL EnableDelayedExpansion EnableExtensions
SET "Message=%~1"

    ECHO !ColorMagenta!!Message!!ColorReset!

EXIT /B 0


::==========================================================================
::  Writes a diagnostic message about script execution.
::--------------------------------------------------------------------------
::  PARAMETERS:
::      Message
::          Diagnostic message.
::==========================================================================
:WriteVerbose
SETLOCAL EnableDelayedExpansion EnableExtensions
SET "Message=%~1"

    IF "!Verbose!"=="1" (
        ECHO !ColorYellow!VERBOSE: !Message!!ColorReset!
    )

EXIT /B 0


::==========================================================================
::  Starts a verbose log section.
::==========================================================================
:BeginVerbose
SETLOCAL EnableDelayedExpansion EnableExtensions

    IF "!Verbose!"=="1" (
        <nul set /p ="!ColorYellow!"
    )

EXIT /B 0


::==========================================================================
::  Stops a verbose log section.
::==========================================================================
:EndVerbose
SETLOCAL EnableDelayedExpansion EnableExtensions

    IF "!Verbose!"=="1" (
        ECHO !ColorReset!
    )

EXIT /B 0


::==========================================================================
::  Writes a verbose message without any additional formatting applied.
::--------------------------------------------------------------------------
::  PARAMETERS:
::      Message
::          Verbose message.
::==========================================================================
:WriteVerboseDirect
SETLOCAL EnableDelayedExpansion EnableExtensions
SET "Message=%*"

    IF "!Verbose!"=="1" (
        <nul set /p =!Message!
    )

EXIT /B 0


::==========================================================================
::  Writes a beginning of the build step.
::--------------------------------------------------------------------------
::  PARAMETERS:
::      Message
::          Step message.
::==========================================================================
:BeginStep
SETLOCAL EnableDelayedExpansion EnableExtensions
SET "Message=%~1"

    ECHO !ColorCyan!!Message!!ColorReset!

EXIT /B 0


::==========================================================================
::  Writes a success message for the latest build step started.
::==========================================================================
:EndStep
SETLOCAL EnableDelayedExpansion EnableExtensions

    ECHO !ColorGreen!Success!ColorReset!

EXIT /B 0


::==========================================================================
::  Writes an execution warning.
::--------------------------------------------------------------------------
::  PARAMETERS:
::      Message
::          Warning message.
::==========================================================================
:WriteWarning
SETLOCAL EnableDelayedExpansion EnableExtensions
SET "Message=%~1"

    ECHO !ColorYellow!WARNING: !Message!!ColorReset!

EXIT /B 0


::==========================================================================
::  Writes an execution error.
::--------------------------------------------------------------------------
::  PARAMETERS:
::      Message
::          Error message.
::==========================================================================
:WriteError
SETLOCAL EnableDelayedExpansion EnableExtensions
SET "Message=%~1"

    ECHO !ColorRed!ERROR: !Message!!ColorReset! 1>&2

EXIT /B 0
