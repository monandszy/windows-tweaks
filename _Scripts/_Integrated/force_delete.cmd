@ECHO OFF
SETLOCAL

REM --- Check if a file/folder path was provided ---
IF "%~1"=="" (
    ECHO ERROR: No file or folder path was provided.
    PAUSE
    EXIT /B 1
)

SET "TARGET_DIR=%*"

ECHO =================================================================
ECHO  Smart Delete Target: "%TARGET_PATH%"
ECHO =================================================================
ECHO.
ECHO [Step 1] Attempting to move to Recycle Bin (Safe Method)...
ECHO.

REM --- Use PowerShell to try moving the item to the Recycle Bin ---
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $path = '%TARGET_PATH%'; Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($path, 'OnlyErrorDialogs', 'SendToRecycleBin', 'ThrowIfOperationFails'); exit 0 } catch { exit 1 }"

REM --- Check if the PowerShell command succeeded (exit code 0) ---
IF %ERRORLEVEL% EQU 0 (
    ECHO.
    ECHO SUCCESS: Item was sent to the Recycle Bin.
    ECHO.
    TIMEOUT /T 3 > NUL
    EXIT /B 0
)

REM --- If we reach here, the safe method failed. Escalate. ---
ECHO.
ECHO FAILED: Could not move to Recycle Bin. The item may be locked,
ECHO in use, or you may lack permissions.
ECHO.
ECHO --------------------------- WARNING ---------------------------
ECHO  The next step is a FORCE DELETE which will PERMANENTLY REMOVE
ECHO  the item. It will NOT go to the Recycle Bin.
ECHO ---------------------------------------------------------------
ECHO.

:CONFIRM
SET /P "CHOICE=Are you sure you want to permanently delete? (Y/N): "
IF /I "%CHOICE%"=="Y" GOTO FORCE_DELETE
IF /I "%CHOICE%"=="N" GOTO CANCEL
GOTO CONFIRM

:FORCE_DELETE
ECHO.
ECHO [Step 2] Initiating Force Delete...

ECHO  - Taking ownership of all items...
takeown /F "%TARGET_PATH%" /R /D Y > NUL 2>&1

ECHO  - Resetting and granting full permissions...
icacls "%TARGET_PATH%" /reset /T /C /Q > NUL 2>&1
icacls "%TARGET_PATH%" /grant Administrators:F /T /C /Q > NUL 2>&1
icacls "%TARGET_PATH%" /grant "%USERNAME%":F /T /C /Q > NUL 2>&1

ECHO  - Attempting permanent removal...
REM --- Check if it's a directory or a file and use the correct command ---
IF EXIST "%TARGET_PATH%\" (
    REM It's a directory
    rd /S /Q "%TARGET_PATH%"
) ELSE (
    REM It's a file
    del /F /Q "%TARGET_PATH%"
)

REM --- Final check ---
IF EXIST "%TARGET_PATH%" (
    ECHO.
    ECHO FAILED: The item could not be permanently deleted.
    ECHO It is likely held open by a critical system process.
    ECHO A system reboot may be required.
) ELSE (
    ECHO.
    ECHO SUCCESS: The item has been permanently deleted.
)
GOTO END

:CANCEL
ECHO.
ECHO Operation cancelled by user.

:END
ECHO.
PAUSE