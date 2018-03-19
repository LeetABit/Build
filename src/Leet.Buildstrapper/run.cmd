@ECHO OFF
REM ==========================================================================
REM   Copyright (c) Leet. All rights reserved.
REM   Licensed under the MIT License.
REM   See License.txt in the project root for full license information.
REM --------------------------------------------------------------------------
REM   This script makes sure that the PowerShell Core in the required version
REM   is installed on the system and then runs 'run.ps1' PowerShell script
REM   passing all current script's parameters to it.
REM ==========================================================================

:Init

SETLOCAL enableDelayedExpansion

SET "PowerShellVersion=6.0.1"
SET "ArchiveFileName=PowerShell-%PowerShellVersion%-win-x64.zip"
SET "ArchiveDownloadPath=https://github.com/PowerShell/PowerShell/releases/download/v%PowerShellVersion%/%ArchiveFileName%"
SET "ArchiveDestinationPath=%TEMP%\%ArchiveFileName%"
SET "InstallationPath=%userprofile%\PowerShell\%PowerShellVersion%"

SET "LightPrefix=1;3"
IF DEFINED APPVEYOR ( SET "LightPrefix=1;9" )

SET "StepColor=[36m"
SET "SuccessColor=[32m"
SET "ModificationColor=[%LightPrefix%5m"
SET "DiagnosticColor=[%LightPrefix%0m"
SET "ErrorColor=[%LightPrefix%1m"
SET "ResetColor=[0m"

ECHO.
CALL :FindPowerShellCore %PowerShellVersion% %InstallationPath%
SET "pwshPath=%result%"

IF [%pwshPath%]==[] (
  IF EXIST %InstallationPath% (
    RMDIR %InstallationPath% /S /Q > NUL
    ECHO %ModificationColor%Removing PowerShell Core installation directory '%InstallationPath%'...%ResetColor%
  )

  CALL :DownloadFile %ArchiveDownloadPath% %ArchiveDestinationPath%
  CALL :ExpandArchive %ArchiveDestinationPath% %InstallationPath%

  IF NOT EXIST %InstallationPath%\pwsh.exe (
    ECHO %ErrorColor%Installation failed.%ResetColor%
    EXIT /B 3
  )

  SET "pwshPath=%InstallationPath%\pwsh.exe"
  ECHO %DiagnosticColor%PowerShell Core v%PowerShellVersion% has been installed at '%InstallationPath%\pwsh.exe'.%ResetColor%
) ELSE (
  ECHO %DiagnosticColor%PowerShell Core v%PowerShellVersion% already installed at '%InstallationPath%\pwsh.exe'.%ResetColor%
)

ECHO %SuccessColor%Success.%ResetColor%
ECHO.

%pwshPath% "%~dp0run.ps1" %*
GOTO End

REM ============================================================================
REM   Finds a path to the PowerShell Core in the required version available
REM   in the current system.
REM ----------------------------------------------------------------------------
REM   %PowerShellVersion%
REM     Version of the PowerShell Core required to be found.
REM
REM   %AdditionalLocation%
REM     Additional location where PowerShell Core may also be located.
REM
REM   returns %result%
REM     Path to the pwsh.exe file found in the current system or nothing
REM     if the required version of PowerShell Core has not been found.
REM ============================================================================
:FindPowerShellCore
SETLOCAL
SET "PowerShellVersion=%1"
SET "AdditionalLocation=%2"

  ECHO %StepColor%Checking PowerShell Core v%PowerShellVersion% availability.%ResetColor%
  SET "pwshPath="
  where /q pwsh.exe > NUL
  IF %ERRORLEVEL% EQU 0 (
    FOR /F "tokens=*" %%p IN ('where pwsh.exe') DO (
      FOR /F "tokens=2" %%q IN ('"%%p" --version') DO (
        IF %%q==v%PowerShellVersion% SET pwshPath="%%p"
      )
    )
  )
  
  IF [%pwshPath%]==[] (
    IF EXIST %AdditionalLocation%\pwsh.exe (
      FOR /F "tokens=2" %%p IN ('"%AdditionalLocation%\pwsh.exe" --version') DO (
        IF %%p==v%PowerShellVersion% SET pwshPath="%AdditionalLocation%\pwsh.exe"
      )
    )
  )

ENDLOCAL & SET result=%pwshPath%
GOTO End

REM ============================================================================
REM   Downloads a file from the remote location.
REM ----------------------------------------------------------------------------
REM   %RemotePath%
REM     Path to the remote file to download.
REM
REM   %DestinationPath%
REM     Path to the destination of the downloaded file.
REM ============================================================================
:DownloadFile
SETLOCAL
SET "RemotePath=%1"
SET "DestinationPath=%2"

  SET "PowerShellCommand="
  SET "PowerShellCommand=%PowerShellCommand% [System.Threading.Thread]::CurrentThread.CurrentCulture = '' ;"
  SET "PowerShellCommand=%PowerShellCommand% [System.Threading.Thread]::CurrentThread.CurrentUICulture = '' ;"
  SET "PowerShellCommand=%PowerShellCommand% $ProgressPreference = 'SilentlyContinue' ;"
  SET "PowerShellCommand=%PowerShellCommand% [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor"
  SET "PowerShellCommand=%PowerShellCommand% [Net.SecurityProtocolType]::Tls11 -bor"
  SET "PowerShellCommand=%PowerShellCommand% [Net.SecurityProtocolType]::Tls ;"
  SET "PowerShellCommand=%PowerShellCommand% Invoke-WebRequest %RemotePath% -OutFile %DestinationPath% ;"
  SET "PowerShellCommand=%PowerShellCommand% exit $LASTEXITCODE"

  ECHO %ModificationColor%Downloading PowerShell Core archive to '%DestinationPath%'...%ResetColor%
  powershell.exe -NoProfile -NoLogo -ExecutionPolicy unrestricted -Command "%PowerShellCommand%"

  IF %ERRORLEVEL% NEQ 0 (
	  ECHO %ErrorColor%Could not download archive.%ResetColor%
    EXIT /B 1
  )

ENDLOCAL
GOTO End

REM ============================================================================
REM   Extracts content of the specified zip archive and deletes archive
REM   regardless of the extraction result.
REM ----------------------------------------------------------------------------
REM   %ArchivePath%
REM     Path to the archive file which content shall be extracted.
REM
REM   %DestinationPath%
REM     Path to the destination of the extracted content.
REM ============================================================================
:ExpandArchive
SETLOCAL
SET "ArchivePath=%1"
SET "DestinationPath=%2"

  SET "PowerShellCommand="
  SET "PowerShellCommand=%PowerShellCommand% [System.Threading.Thread]::CurrentThread.CurrentCulture = '' ;"
  SET "PowerShellCommand=%PowerShellCommand% [System.Threading.Thread]::CurrentThread.CurrentUICulture = '' ;"
  SET "PowerShellCommand=%PowerShellCommand% $ProgressPreference = 'SilentlyContinue' ;"
  SET "PowerShellCommand=%PowerShellCommand% Add-Type -A 'System.IO.Compression.FileSystem' ;"
  SET "PowerShellCommand=%PowerShellCommand% Expand-Archive -Path %ArchivePath% -DestinationPath %DestinationPath% -Force ;"
  SET "PowerShellCommand=%PowerShellCommand% exit $LASTEXITCODE"

  ECHO %ModificationColor%Extracting PowerShell Core archive to '%DestinationPath%'...%ResetColor%
  powershell.exe -NoProfile -NoLogo -ExecutionPolicy unrestricted -Command "%PowerShellCommand%"
  SET "extractionError=!ERRORLEVEL!"

  ECHO %ModificationColor%Deleting '%ArchiveDestinationPath%'...%ResetColor%
  DEL /F /Q %ArchiveDestinationPath%

  IF NOT "!extractionError!"=="0" (
	  ECHO %ErrorColor%Could not extract PowerShell Core v%PowerShellVersion%.%ResetColor%
    EXIT /B 2
  )

ENDLOCAL
GOTO End

:End
