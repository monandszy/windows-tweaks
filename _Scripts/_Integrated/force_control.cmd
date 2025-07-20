@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

REM =================================================================
REM --- Check for Administrator Privileges ---
REM =================================================================
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
IF '%errorlevel%' NEQ '0' (
    ECHO ERROR: This script requires Administrator privileges.
    ECHO Please right-click the script and select "Run as administrator".
    ECHO.
    PAUSE
    EXIT /B 1
)

REM =================================================================
REM --- Check if a path was provided ---
REM =================================================================
IF "%~1"=="" (
    ECHO ERROR: No file or directory path was provided.
    ECHO Usage: %~n0 "C:\Path\To\Your\Item"
    PAUSE
    EXIT /B 1
)

SET "TARGET_PATH=%~1"
SET "TARGET_TYPE="

REM --- Verify the path exists and determine its type (File or Directory) ---
IF EXIST "%TARGET_PATH%\" (
    SET "TARGET_TYPE=Directory"
) ELSE IF EXIST "%TARGET_PATH%" (
    SET "TARGET_TYPE=File"
) ELSE (
    ECHO ERROR: The specified file or directory does not exist.
    ECHO Path: "%TARGET_PATH%"
    PAUSE
    EXIT /B 1
)


ECHO =================================================================
ECHO  Full Unlock for !TARGET_TYPE!:
ECHO  "!TARGET_PATH!"
ECHO.
ECHO  This will:
IF "!TARGET_TYPE!"=="Directory" (
    ECHO  1. Find and stop processes locking items in this folder.
    ECHO  2. Stop all running processes from the folder itself.
    ECHO  3. Take ownership and reset permissions for full access.
    ECHO  4. Remove the 'Read-Only' attribute from all items.
) ELSE (
    ECHO  1. Find and stop the process locking this file.
    ECHO  2. Take ownership and reset permissions for full access.
    ECHO  3. Remove the 'Read-Only' attribute from the file.
)
ECHO =================================================================
ECHO.
PAUSE
ECHO.

ECHO [Step 1] Finding processes with open handles to the target...
REM --- Use handle.exe from Sysinternals if it's in the PATH ---
WHERE handle.exe >nul 2>nul
IF %ERRORLEVEL% EQU 0 (
    ECHO Found handle.exe. Searching for locking processes...
    SET "found_handles=0"
    FOR /F "tokens=3,6" %%a IN ('handle.exe -nobanner -a "%TARGET_PATH%" 2^>nul') DO (
        IF "%%a" NEQ "" (
            SET "found_handles=1"
            ECHO   - Found locked handle by process with PID: %%a. Terminating...
            taskkill /F /PID %%a
        )
    )
    IF "!found_handles!"=="0" (
        ECHO No active file handles found for this target.
    )
    ECHO Success.
) ELSE (
    ECHO WARNING: handle.exe was not found in your system's PATH.
    ECHO This step is crucial for unlocking files in use by other programs.
    ECHO Download: https://docs.microsoft.com/en-us/sysinternals/downloads/handle
    ECHO Place handle.exe in C:\Windows\System32 to enable this check.
    ECHO Skipping this step.
)
ECHO.

REM --- The following steps are specific to the target type ---

IF "!TARGET_TYPE!"=="Directory" (
    ECHO [Step 2 of 4] Stopping all processes running from this directory...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { param($path) Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -like \"$path\*\" } | Stop-Process -Force -ErrorAction SilentlyContinue }" -path "%TARGET_PATH%"
    ECHO Success.
    ECHO.

    ECHO [Step 3 of 4] Taking ownership and resetting permissions (Recursive)...
    takeown /F "%TARGET_PATH%" /R /D Y >nul
    icacls "%TARGET_PATH%" /grant Administrators:F /T /C /Q
    icacls "%TARGET_PATH%" /grant "%USERNAME%":F /T /C /Q
    ECHO Success.
    ECHO.

    ECHO [Step 4 of 4] Removing the 'Read-Only' attribute (Recursive)...
    attrib -R "%TARGET_PATH%\*" /S /D
    ECHO Success.
)

IF "!TARGET_TYPE!"=="File" (
    ECHO [Step 2 of 3] Taking ownership and resetting permissions...
    takeown /F "%TARGET_PATH%" /D Y >nul
    icacls "%TARGET_PATH%" /grant Administrators:F /C /Q
    icacls "%TARGET_PATH%" /grant "%USERNAME%":F /C /Q
    ECHO Success.
    ECHO.

    ECHO [Step 3 of 3] Removing the 'Read-Only' attribute...
    attrib -R "%TARGET_PATH%"
    ECHO Success.
)

ECHO.
ECHO =================================================================
ECHO  UNLOCK COMPLETE
ECHO  The item should now be fully accessible and deletable.
ECHO =================================================================
ECHO.
PAUSE
ENDLOCAL