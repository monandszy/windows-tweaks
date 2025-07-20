@ECHO OFF
SETLOCAL

REM --- Check if a directory path was provided as an argument ---
IF "%~1"=="" (
    ECHO ERROR: No directory path was provided.
    ECHO Usage: %~n0 "C:\Path\To\Folder"
    PAUSE
    EXIT /B 1
)

SET "TARGET_DIR=%*"

ECHO.
ECHO ==========================================================
ECHO  Attempting to stop all processes running from:
ECHO  "%TARGET_DIR%"
ECHO  (This includes all subdirectories)
ECHO ==========================================================
ECHO.

REM --- Use PowerShell to find and stop the processes ---
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '%TARGET_DIR%\*' } | Stop-Process -Force -ErrorAction SilentlyContinue"

ECHO.
ECHO Operation complete.
PAUSE