<#
.SYNOPSIS
    Scans for connected drives, prompts the user for new drives, and asynchronously runs or deploys a backup script in a new visible window.

.DESCRIPTION
    This script is designed to be run at startup. It checks for drives that can be used for backup.
    If a drive is already set up, it runs the backup. If a drive is new, it asks the user for permission
    to copy the backup files. If the user denies permission, it remembers this choice by creating a
    '.backup_declined' file and won't ask again for that drive. For each approved drive, it launches the backup process
    asynchronously in its own command prompt window. The main script then exits immediately,
    allowing the startup process to continue without delay.
#>

# --- Configuration ---
$BackupFolderName = "_Backup"
$BackupScriptName = "backup.cmd"
$DeclineFileName = ".backup_declined" # File to signify that the user has opted out for a specific drive.

# --- Functions ---
function Write-OutputMessage {
    param([string]$Message)
    # This ensures the message is visible in the interactive console where the user gives input.
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
            $DeclineFilePath = Join-Path -Path $DriveRoot -ChildPath $DeclineFileName

            # First, check if the user has previously declined to use this drive.
            if (Test-Path -Path $DeclineFilePath) {
                Write-OutputMessage "Skipping drive $DriveRoot as per previous user decision."
                continue # Skip to the next drive
            }

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
                # Drive is new and not declined. Ask the user before proceeding.
                $PromptMessage = "New drive $DriveRoot detected. Set it up for backup? [y/n]"
                $UserInput = Read-Host -Prompt $PromptMessage
                
                if ($UserInput -eq 'y') {
                    Write-OutputMessage "User approved. Deploying backup files..."
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
                else {
                    # User entered 'n' or any other value, treat as a 'no'.
                    Write-OutputMessage "User declined. Remembering choice for $DriveRoot."
                    try {
                        New-Item -Path $DeclineFilePath -ItemType File -ErrorAction Stop | Out-Null
                        Write-OutputMessage "Created decline file at '$DeclineFilePath'."
                    }
                    catch {
                        Write-OutputMessage "ERROR: Could not create decline file at '$DeclineFilePath'. You may be prompted again. Error: $_"
                    }
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
