@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

REM --- Check if a directory path was provided ---
IF "%~1"=="" (
    ECHO ERROR: No directory path was provided.
    ECHO Usage: %~n0 "C:\Path\To\Folder"
    PAUSE
    EXIT /B 1
)

SET "TARGET_DIR=%*"
SET "CURRENT_USER=%USERNAME%"

ECHO.
ECHO =================================================================
ECHO  Starting ADVANCED ownership and permission reset for:
ECHO  "%TARGET_DIR%"
ECHO.
ECHO  Targeting User: %CURRENT_USER%
ECHO =================================================================
ECHO.

ECHO [Step 1 of 3] Forcibly taking ownership for the Administrators group...
takeown /F "%TARGET_DIR%" /R /D Y
IF !ERRORLEVEL! NEQ 0 (
    ECHO FAILED: Could not take ownership. Halting script.
    PAUSE
    EXIT /B 1
)
ECHO Success.

ECHO.
ECHO [Step 2 of 3] Resetting all permissions on the folder structure...
ECHO This clears out any broken or conflicting permissions.
icacls "%TARGET_DIR%" /reset /T /C /Q
IF !ERRORLEVEL! NEQ 0 (
    ECHO WARNING: Some errors occurred during permission reset, continuing anyway...
)
ECHO Success.

ECHO.
ECHO [Step 3 of 3] Granting FULL CONTROL to Administrators and %CURRENT_USER%...
icacls "%TARGET_DIR%" /grant Administrators:F /T /C /Q
icacls "%TARGET_DIR%" /grant "%CURRENT_USER%":F /T /C /Q

IF !ERRORLEVEL! EQU 0 (
    ECHO.
    ECHO SUCCESS! Ownership taken and full control granted.
) ELSE (
    ECHO.
    ECHO FAILED: An error occurred during the final grant command.
    ECHO Please check the output above.
)

ECHO.
PAUSE