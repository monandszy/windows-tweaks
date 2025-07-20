<#
.SYNOPSIS
    Scans for connected drives and asynchronously runs or deploys a backup script in a new visible window.

.DESCRIPTION
    This script is designed to be run at startup. For each target drive, it launches the backup process
    asynchronously in its own command prompt window. The main script then exits immediately,
    allowing the startup process to continue without delay.
#>

# --- Configuration ---
$BackupFolderName = "_Backup"
$BackupScriptName = "backup.cmd"

# --- Functions ---
function Write-OutputMessage {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format "HH:mm:ss")] $Message"
}

# --- Main Script Logic ---
try {
    Write-OutputMessage "Script started. Asynchronously launching backups in new windows..."

    $SourceBackupPath = Join-Path -Path $PSScriptRoot -ChildPath $BackupFolderName

    if (-not (Test-Path -Path $SourceBackupPath)) {
        Write-OutputMessage "CRITICAL ERROR: Source folder '$SourceBackupPath' not found. Script exiting."
        exit 1
    }

    $SystemDrive = $env:SystemDrive
    $Drives = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -in ('Fixed', 'Removable') -and ($_.DriveLetter + ":") -ne $SystemDrive }

    if ($null -eq $Drives) {
        Write-OutputMessage "No suitable target drives found."
    }
    else {
        foreach ($Drive in $Drives) {
            $DriveRoot = $Drive.DriveLetter + ":"
            Write-OutputMessage "Checking drive $DriveRoot..."
            $TargetScriptPath = Join-Path -Path $DriveRoot -ChildPath (Join-Path $BackupFolderName $BackupScriptName)

            if (Test-Path -Path $TargetScriptPath) {
                Write-OutputMessage "Backup script found. Launching in a new window..."
                try {
                    # Execute the script without waiting. It will open in its own visible window.
                    Start-Process -FilePath $TargetScriptPath -WorkingDirectory (Split-Path $TargetScriptPath) -ErrorAction Stop
                    Write-OutputMessage "Launched existing script on $DriveRoot."
                }
                catch {
                    Write-OutputMessage "ERROR: Failed to launch script at '$TargetScriptPath'. Error: $_"
                }
            }
            else {
                Write-OutputMessage "Backup script not found. Deploying..."
                $DestinationPath = Join-Path -Path $DriveRoot -ChildPath $BackupFolderName
                
                try {
                    Copy-Item -Path $SourceBackupPath -Destination $DestinationPath -Recurse -Force -ErrorAction Stop
                    Write-OutputMessage "Successfully copied '$SourceBackupPath' to '$DestinationPath'."

                    Write-OutputMessage "Launching newly deployed script in a new window..."
                    # Execute the newly copied script without waiting.
                    Start-Process -FilePath $TargetScriptPath -WorkingDirectory (Split-Path $TargetScriptPath) -ErrorAction Stop
                    Write-OutputMessage "Launched new script on $DriveRoot."
                }
                catch {
                    Write-OutputMessage "ERROR: Failed to deploy or run the backup script on '$DriveRoot'. Error: $_"
                }
            }
        }
    }
}
catch {
    Write-OutputMessage "An unexpected error occurred: $_"
}
finally {
    Write-OutputMessage "Script finished launching tasks and is now closing."
}