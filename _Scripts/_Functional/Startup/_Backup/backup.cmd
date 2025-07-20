@echo off
:: Restic Portable Backup Script

:: --- CONFIGURATION ---
:: Paths are now relative to the current user's home directory (%USERPROFILE%).
:: Add the subdirectories you want to back up here, separated by spaces.
:: This is now portable across different Windows machines and users!
set BACKUP_SOURCES=^
    "%USERPROFILE%\Documents" ^
    "%USERPROFILE%\Desktop" ^
    "%USERPROFILE%\_My" ^
    "%USERPROFILE%\_MyPrograms" ^
    "%USERPROFILE%\AppData" ^
    "%USERPROFILE%\.ssh" ^
    "%USERPROFILE%\VirtualBox VMs" ^

:: --- SCRIPT ---

:: Set paths relative to the script's location for portability
set SCRIPT_DIR=%~dp0
set REPO_PATH=%SCRIPT_DIR%_Repo
set PASSWORD_FILE=%SCRIPT_DIR%password.txt
set EXCLUDE_FILE=%SCRIPT_DIR%excludes.txt

:: Change the current directory to the script's directory
cd /d "%SCRIPT_DIR%"

echo =======================================================
echo.
echo  Restic Portable Backup
echo  Repository: %REPO_PATH%
echo  Sources:    %BACKUP_SOURCES%
echo.
echo =======================================================

:: Initialize the repository if it doesn't exist (first time run)
if not exist "%REPO_PATH%\config" (
    echo [INFO] Repository not found. Initializing a new one...
    .\restic.exe init --repo "%REPO_PATH%" --password-file "%PASSWORD_FILE%"
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to initialize repository.
        pause
        exit /b
    )
)

echo.
echo [STEP 1/2] Starting backup...
:: The backup command with all the options
.\restic.exe backup ^
    --repo "%REPO_PATH%" ^
    --password-file "%PASSWORD_FILE%" ^
    --exclude-file "%EXCLUDE_FILE%" ^
    --verbose ^
    %BACKUP_SOURCES%

echo.
echo [STEP 2/2] Pruning old backups to save space...
:: This policy keeps the last 7 daily, 4 weekly, and 12 monthly snapshots.
.\restic.exe forget ^
    --repo "%REPO_PATH%" ^
    --password-file "%PASSWORD_FILE%" ^
    --prune ^
    --keep-daily 7 ^
    --keep-weekly 4 ^
    --keep-monthly 12

echo.
echo =======================================================
echo  Backup and prune complete!
echo =======================================================
echo.
pause