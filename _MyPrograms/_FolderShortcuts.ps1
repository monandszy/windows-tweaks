<#
.SYNOPSIS
Creates shortcuts of folders and moves them to the current user's Start Menu Programs folder
based on a predefined list of global/user-variable directory paths.

.DESCRIPTION
This script automates the creation of .lnk shortcuts that point directly to
specified directories. Target directories are defined by an internal array
containing absolute paths or paths using environment variables
(like $env:USERPROFILE, $env:APPDATA).

The entries in the list should be the full path to the directory you want
to create a shortcut *to*. Shortcuts are placed directly in the root of the
user's Start Menu Programs folder.

General behavior:
- Resolves paths using environment variables before processing.
- Validates that the resolved path exists and is a directory.
- Targets the current user's Start Menu Programs folder.
- Shortcut name is the source folder's name (`FolderName.lnk`).
- Shortcut "Start in" is set to the source folder's path.
- Uses WScript.Shell COM object.
- Skips if a shortcut with the same name already exists in the target location.
- Provides console output and a final summary.

IMPORTANT: The `$FolderSourcePaths` array MUST be edited by the user.

.EXAMPLE
PS C:> .\Create-StartMenuFolderShortcuts.ps1	
(Assumes the list is configured)
If `$FolderSourcePaths` contains:
- "C:\PortableApps\Utils\": Shortcut created in `C:\Users\CurrentUser\AppData\Microsoft\Windows\Start Menu\Programs\Utils.lnk`
- "$env:USERPROFILE\Desktop\Games": Shortcut created in `C:\Users\CurrentUser\AppData\Microsoft\Windows\Start Menu\Programs\Games.lnk`.
#>

# --- DEFINE YOUR SOURCE FOLDER PATHS HERE ---
# These are absolute paths to DIRECTORIES or paths using environment variables.
# Shortcut name will be the name of the folder.

$FolderSourcePaths = @(
    "C:\Program Files",
    "C:\Windows",
    "C:\Users",
    "$env:USERPROFILE",
    "$env:USERPROFILE\_My",
    "$env:USERPROFILE\_MyPrograms",
    "$env:USERPROFILE\VirtualBox VMs\VMShared",
    "$env:USERPROFILE\AppData",
    "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Themes",
    "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
)
# --- END OF PREDEFINED PATHS ---

# Define the target Windows special folder
$startMenuProgramsPath = [Environment]::GetFolderPath("Programs")

# Validate target folder
if (-not (Test-Path $startMenuProgramsPath -PathType Container)) {
    Write-Error "Start Menu Programs folder not found: '$startMenuProgramsPath'. This is unexpected. Aborting."
    exit 1
}

# Create WScript.Shell COM object
$shell = $null
try {
    $shell = New-Object -ComObject WScript.Shell
}
catch {
    Write-Error "Failed to create WScript.Shell COM object. Error: $($_.Exception.Message)"
    exit 1
}

Write-Host "Targeting Start Menu Programs folder: '$startMenuProgramsPath'"
Write-Host "----------------------------------------"

$createdCount = 0
$skippedCount = 0
$errorCount = 0

#region Process Folder Source Paths

Write-Host "`nProcessing folder sources from `$FolderSourcePaths...`n"

foreach ($sourceFolderEntry in $FolderSourcePaths) {
    $normalizedSourcePathString = $sourceFolderEntry.Replace('/', '\').Trim() # Normalize slashes and trim

    # Resolve environment variables and relative paths within them
    $fullSourceFolderPath = ""
    try {
        # Use Resolve-Path to handle environment variables and resolve to a concrete path
        # -ErrorAction Stop ensures exceptions are caught. Use -ErrorVariable to capture specific errors
        $resolveErrors = @()
        $resolvedPathItem = Resolve-Path -Path $normalizedSourcePathString -ErrorAction SilentlyContinue -ErrorVariable resolveErrors

        if ($resolveErrors.Count -gt 0) {
             # Resolve-Path failed entirely
             Write-Error "Failed to resolve source folder path '$normalizedSourcePathString' from entry '$sourceFolderEntry'. Error: $($resolveErrors[0].Exception.Message). Skipping this entry."
             $errorCount++ # Count failure to resolve source as an error for the entry
             continue
        } elseif ($null -eq $resolvedPathItem) {
             # Resolve-Path returned null but didn't throw (less common, but handle)
             Write-Error "Resolve-Path returned null for source folder path '$normalizedSourcePathString' from entry '$sourceFolderEntry'. Skipping this entry."
             $errorCount++
             continue
        } else {
             $fullSourceFolderPath = $resolvedPathItem.Path
        }
    }
    catch {
         # Catch any unexpected errors from Resolve-Path that SilentlyContinue might miss (shouldn't happen with ErrorVariable, but safe)
         Write-Error "Unexpected error resolving source folder path '$normalizedSourcePathString' from entry '$sourceFolderEntry'. Error: $($_.Exception.Message). Skipping this entry."
         $errorCount++
         continue
    }

    Write-Host "Processing folder entry: '$sourceFolderEntry' (resolved folder: '$fullSourceFolderPath')"

    # Validate that the resolved path is a directory
    if (-not (Test-Path $fullSourceFolderPath -PathType Container)) {
        Write-Warning "Resolved path '$fullSourceFolderPath' for entry '$sourceFolderEntry' is not a directory or does not exist. Skipping."
        $skippedCount++ # Count as skipped attempt for this entry
        continue
    }

    # Get the name of the source folder for the shortcut name
    $folderName = Split-Path -Path $fullSourceFolderPath -Leaf

    # Handle potential empty name if path is just a drive root (e.g., C:\)
    if ([string]::IsNullOrWhiteSpace($folderName)) {
        # Use the drive letter as the name for C:\, D:\ etc.
        $driveLetterMatch = $fullSourceFolderPath -match '^([a-zA-Z]):\\?$' # Match C:\ or C:
        if ($driveLetterMatch) {
            $folderName = $driveLetterMatch.Groups[1].Value + " Drive" # e.g., "C Drive"
        } else {
             Write-Error "Could not determine name for shortcut to source folder '$fullSourceFolderPath' from entry '$sourceFolderEntry'. Skipping."
             $errorCount++
             continue # Cannot proceed without a name
        }
    }

    # Construct the final shortcut path in the Start Menu Programs root
    $shortcutName = "$($folderName).lnk"
    $shortcutPath = Join-Path -Path $startMenuProgramsPath -ChildPath $shortcutName

    # Check if target shortcut path already exists
    if (Test-Path $shortcutPath -PathType Leaf) {
        Write-Warning "  Shortcut '$shortcutName' already exists in '$startMenuProgramsPath'. Skipping."
        $skippedCount++
        continue # Skip this specific shortcut creation attempt
    }

    # Create the shortcut
    try {
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $fullSourceFolderPath # Target is the folder path
        $shortcut.WorkingDirectory = $fullSourceFolderPath # Working directory is also the folder path
        $shortcut.Save()
        Write-Host "  Created shortcut: '$shortcutName' in '$startMenuProgramsPath'"
        $createdCount++
    }
    catch {
        Write-Error "  Failed to create shortcut '$shortcutName' for folder '$fullSourceFolderPath' in '$startMenuProgramsPath'. Error: $($_.Exception.Message)"
        $errorCount++
    }
}

#endregion

# Summary
Write-Host "----------------------------------------"
Write-Host "Script Finished."
Write-Host "Total Folder Shortcuts Created: $createdCount"
Write-Host "Total Folder Paths Skipped: $skippedCount (source folder not found or shortcut already exists)"
Write-Host "Total Errors encountered    : $errorCount (failed to resolve source path, create shortcut, or name shortcut)"
Write-Host "----------------------------------------"

# Release COM object
if ($shell) {
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
    $shell = $null
}
pause