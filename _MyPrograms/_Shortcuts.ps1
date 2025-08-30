
<#
.SYNOPSIS
Creates shortcuts for applications in the Windows user's Start Menu and Startup folders.
It also automatically creates shortcuts to the parent folders of those applications.

.DESCRIPTION
This script automates the creation of .lnk shortcuts. Targets are defined by two internal arrays relative to a $RootDirectory:
1. $PredefinedRelativeExePaths: For application shortcuts placed only in the Start Menu Programs folder.
2. $StartupRelativeExePaths: For application shortcuts placed in BOTH the Start Menu Programs folder and the Startup folder.

For the application lists, the script supports two types:
1. Exact Relative File Paths (e.g., "FolderA\App.exe"):
   - Creates a shortcut directly in the target folder (Start Menu Programs root, Startup root, or both).
2. Wildcard Directory Paths (e.g., "FolderB\*"):
   - Scans the specified directory non-recursively for all allowed file types (.exe, .bat, .cmd, .code-workspace).
   - Creates a new subfolder inside the target folder(s) named after the source directory (e.g., "FolderB").
   - Places shortcuts for all found files into this new subfolder.

General behavior:
- Uses `$RootDirectory` (or current location) as the base for finding source files and folders.
- For each unique program folder processed, it automatically creates a corresponding folder shortcut in the Start Menu Programs folder.
- Skips creation if a shortcut with the same name already exists in the target location.
- Provides console output and a final summary of actions taken.

IMPORTANT: The `$PredefinedRelativeExePaths` and `$StartupRelativeExePaths` arrays MUST be edited by the user.

.PARAMETER RootDirectory
The root directory for resolving relative paths to source executables and folders.
Defaults to current location.

.EXAMPLE
PS C:> .\Create-AdvancedShortcuts.ps1

(Assumes script is run from the desired RootDirectory and the arrays are configured)
If `$PredefinedRelativeExePaths` contains "Utils\Tool.exe", two shortcuts are created:
- Application: `...\Start Menu\Programs\Tool.lnk`
- Parent Folder: `...\Start Menu\Programs\Utils.lnk`

If `$StartupRelativeExePaths` contains "BackgroundTasks\*":
- For `.\BackgroundTasks\Task1.exe`, shortcuts are created in:
  `...\Start Menu\Programs\BackgroundTasks\Task1.lnk`
  `...\Startup\BackgroundTasks\Task1.lnk`
- And a single folder shortcut is also created: `...\Start Menu\Programs\BackgroundTasks.lnk`

.NOTES
Prerequisites: PowerShell, WScript.Shell COM object.
Configuration: Edit the `$PredefinedRelativeExePaths` and `$StartupRelativeExePaths` arrays.
Permissions: Required to create files and directories in the user's Start Menu and Startup folders.
#>
[CmdletBinding()]
param(
    [string]
    [ValidateNotNullOrEmpty()]
    $RootDirectory = (Get-Location).Path
)

# --- DEFINE YOUR RELATIVE EXE PATHS HERE ---
# These will be added to the User's Start Menu -> Programs folder
$PredefinedRelativeExePaths = @(
    "Development\PortableGit\git-bash.exe",
    "Development\PortableGit\git-cmd.exe",
    "Development\android\Universal Android Debloater.exe",
    "Development\AutoHotkey_1\*",
    "Development\AutoHotkey_2\*",
    "Portable\Audacity\Audacity.exe",
    "Portable\Colora\Colora.exe",
    "Portable\DMDE\dmde.exe",
    "Portable\Everything\everything.exe",
    "Portable\GIMPPortable\GIMPPortable.exe",
    "Portable\Inkscape\bin\inkscape.exe",
    "Portable\KDEconnect\bin\kdeconnect-app.exe",
    "Portable\LibreWolf Portable\LibreWolf-Portable.exe",
    "Portable\LibreWolf Portable\LibreWolfSocials.bat",
    "Portable\LibreWolf Portable\LibreWolfWork.bat",
    "Portable\Okular\bin\okular.exe",
    "Portable\olive-editor\olive-editor.exe",
    "Portable\PaintDotNet\PaintDotNetPortable.exe",
    "Portable\qimgv-video\mpv.exe",
    "Portable\qimgv-video\qimgv.exe",
    "Portable\SysInternals All\*", # Example wildcard entry
    "Portable\Vial\Vial.exe",
    "Portable\ungoogled-chromium-portable\chrome.exe",
    "Portable\Vivaldi\vivaldi.bat",
    "Programing\vscodium-portable\VSCodium.exe",
    "Programing\NetworkMiner_2-9\NetworkMiner.exe",
    "Programing\WiresharkPortable64\WiresharkPortable64.exe",
    "WindowsManagement\BCUninstaller\BCUninstaller.exe",
    "WindowsManagement\ClickMonitorDDC_7_2\ClickMonitorDDC_7_2.exe",
    "WindowsManagement\Default Programs Editor\Default Programs Editor.exe",
    "WindowsManagement\Dimmer\Dimmer.exe",
    "WindowsManagement\hwmonitor\HWMonitor_x64.exe",
    "WindowsManagement\MajorGeeks Windows Tweaks\MajorGeeks Windows Tweaks.exe",
    "WindowsManagement\shexview\shexview.exe",
    "WindowsManagement\shmnview\shmnview.exe",
    "WindowsManagement\ThrottleStop\ThrottleStop.exe",
    "WindowsManagement\Ultimate Windows Tweaker\Ultimate Windows Tweaker.exe",
    "WindowsManagement\winaerotweaker\WinaeroTweaker.exe",
    "WindowsManagement\Wireless Gaming Mouse AP\Eagle Mouse.exe",
    "Portable\SSHFS\SSHFS-Win Manager.exe",
    "WindowsManagement\NilesoftShell\shell.exe",
    "WindowsManagement\nircmd-x64\nircmd.exe",
    "WindowsManagement\ExeInstall\*",
    "Programing\Nvim\nvim.cmd",
    "Portable\LibreOfficePortable\*",
    "Programing\win-vind\win-vind.exe",
    "Programing\intellij-idea-ultima\intellij-idea-ultimate-portable.exe",
    "Programing\workspaces\*",
    "Programing\android-studio-portable\android-studio-portable.exe",
    "Development\podman-desktop\podman-desktop.exe",
    "WindowsManagement\ventoy\*"
)

# Define the list of extensions to look for
$AllowedExtensions = @("*.exe", "*.bat", "*.cmd", "*.code-workspace")

# These will be added to the User's Start Menu -> Programs folder AND the Startup folder
$StartupRelativeExePaths = @(
 "Portable\FlowLauncher\Flow.Launcher.exe",
 "Portable\Rainmeter\Rainmeter.exe",
 "Portable\ShareX\ShareX.exe",
 "Portable\Simplewall\simplewall.exe"
)
# --- END OF PREDEFINED PATHS ---

# Define target Windows special folders
$startMenuProgramsPath = [Environment]::GetFolderPath("Programs")
$startupPath = [Environment]::GetFolderPath("Startup")


if (-not (Test-Path $startMenuProgramsPath -PathType Container)) {
    Write-Error "Start Menu Programs folder not found: '$startMenuProgramsPath'. This is unexpected. Aborting."
    exit 1
}
if (-not (Test-Path $startupPath -PathType Container)) {
    Write-Error "Startup folder not found: '$startupPath'. This is unexpected. Aborting."
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

Write-Host "Targeting Start Menu Programs: '$startMenuProgramsPath'"
Write-Host "Targeting Startup folder      : '$startupPath'"
Write-Host "Using Root Directory          : '$RootDirectory'"
Write-Host "----------------------------------------"

$createdCount = 0
$skippedCount = 0
$errorCount = 0
# List to track folders for which shortcuts have already been created, to avoid duplicates
$processedFolderPaths = [System.Collections.Generic.List[string]]::new()


#region Helper Functions for Creating Shortcuts

function Create-AppShortcut {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$ExeFileInfo,
        [Parameter(Mandatory=$true)]
        [string]$TargetFolderPath,
        [Parameter(Mandatory=$true)]
        [__ComObject]$ShellObject, # Type specific to WScript.Shell
        [Parameter(Mandatory=$true)]
        [ref]$CreatedCounter,
        [Parameter(Mandatory=$true)]
        [ref]$SkippedCounter,
        [Parameter(Mandatory=$true)]
        [ref]$ErrorCounter
    )

    try {
        $shortcutName = "$($ExeFileInfo.BaseName).lnk"
        $shortcutPath = Join-Path -Path $TargetFolderPath -ChildPath $shortcutName

        if (Test-Path $shortcutPath) {
            Write-Warning "  Shortcut '$shortcutName' already exists in '$TargetFolderPath'. Skipping."
            $SkippedCounter.Value++
            return # Exit the function for this specific shortcut creation attempt
        }

        # Ensure the target subfolder exists if it's not the root
        if ($TargetFolderPath -ne $startMenuProgramsPath -and $TargetFolderPath -ne $startupPath) {
             if (-not (Test-Path $TargetFolderPath -PathType Container)) {
                Write-Host "  Creating target subfolder: '$TargetFolderPath'"
                try {
                    $null = New-Item -Path $TargetFolderPath -ItemType Directory -ErrorAction Stop
                }
                catch {
                    Write-Error "  Failed to create target subfolder '$TargetFolderPath'. Error: $($_.Exception.Message). Cannot create shortcut."
                    $ErrorCounter.Value++
                    return # Exit the function due to folder creation failure
                }
            }
        }

        $shortcut = $ShellObject.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $ExeFileInfo.FullName
        $shortcut.WorkingDirectory = $ExeFileInfo.DirectoryName
        $shortcut.Save()
        Write-Host "  Created shortcut: '$shortcutName' in '$TargetFolderPath'"
        $CreatedCounter.Value++

    }
    catch {
        Write-Error "  Failed to create shortcut for '$($ExeFileInfo.FullName)' in '$TargetFolderPath'. Error: $($_.Exception.Message)"
        $ErrorCounter.Value++
    }
}

function Create-FolderShortcut {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.IO.DirectoryInfo]$FolderInfo,
        [Parameter(Mandatory=$true)]
        [string]$ProgramsFolderPath,
        [Parameter(Mandatory=$true)]
        [__ComObject]$ShellObject,
        [Parameter(Mandatory=$true)]
        [ref]$CreatedCounter,
        [Parameter(Mandatory=$true)]
        [ref]$SkippedCounter,
        [Parameter(Mandatory=$true)]
        [ref]$ErrorCounter
    )
    try {
        $shortcutName = "$($FolderInfo.Name).lnk"
        $shortcutPath = Join-Path -Path $ProgramsFolderPath -ChildPath $shortcutName

        if (Test-Path $shortcutPath) {
            Write-Warning "  Folder shortcut '$shortcutName' already exists in '$ProgramsFolderPath'. Skipping."
            $SkippedCounter.Value++
            return
        }

        $shortcut = $ShellObject.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $FolderInfo.FullName
        $shortcut.WorkingDirectory = $FolderInfo.FullName
        $shortcut.Save()
        Write-Host "  Created folder shortcut: '$shortcutName' in '$ProgramsFolderPath'"
        $CreatedCounter.Value++
    }
    catch {
        Write-Error "  Failed to create folder shortcut for '$($FolderInfo.FullName)'. Error: $($_.Exception.Message)"
        $ErrorCounter.Value++
    }
}

#endregion

#region Process PredefinedRelativeExePaths (Start Menu Only)

Write-Host "`nProcessing Start Menu Only entries from `$PredefinedRelativeExePaths...`n"

foreach ($entryPath in $PredefinedRelativeExePaths) {
    $normalizedEntryPath = $entryPath.Replace('/', '\').Trim() # Normalize slashes and trim

    # --- HANDLE WILDCARD DIRECTORY SCANS (entries ending with \*) ---
    if ($normalizedEntryPath.EndsWith('\*')) {
        $sourceDirRelativePath = $normalizedEntryPath.Substring(0, $normalizedEntryPath.Length - 2) # Remove '\*'
        $fullSourceDirPath = Join-Path -Path $RootDirectory -ChildPath $sourceDirRelativePath

        Write-Host "Processing wildcard entry: '$entryPath' (source directory: '$fullSourceDirPath')"

        if (-not (Test-Path $fullSourceDirPath -PathType Container)) {
            Write-Warning "Source directory '$fullSourceDirPath' for wildcard entry '$entryPath' not found. Skipping this entry."
            $skippedCount++ # Count as skipped attempt for this entry configuration
            continue
        }

        # Determine name for the subfolder in Start Menu (name of the source folder)
        # Special case: "*" should not create a subfolder named after RootDirectory
        if ($sourceDirRelativePath -eq "" -or $sourceDirRelativePath -eq ".") {
            $startMenuTargetSubFolderPath = $startMenuProgramsPath
            Write-Host "  Targeting Start Menu root folder for wildcard entry '*'"
        } else {
            $sourceFolderName = Split-Path -Leaf $fullSourceDirPath
            $startMenuTargetSubFolderPath = Join-Path -Path $startMenuProgramsPath -ChildPath $sourceFolderName
            Write-Host "  Targeting Start Menu subfolder: '$startMenuTargetSubFolderPath'"
        }

        # Use -Include to find all files matching the extensions in $AllowedExtensions
        $exeFilesInSourceDir = Get-ChildItem -Path $fullSourceDirPath -Include $AllowedExtensions -File -Depth 0 -ErrorAction SilentlyContinue

        if ($null -eq $exeFilesInSourceDir -or $exeFilesInSourceDir.Count -eq 0) {
            Write-Host "  No files with allowed extensions found in '$fullSourceDirPath'."
            continue
        }

        Write-Host "  Found $($exeFilesInSourceDir.Count) matching file(s) in '$fullSourceDirPath'."

        foreach ($exeFileInstance in $exeFilesInSourceDir) {
            Create-AppShortcut -ExeFileInfo $exeFileInstance -TargetFolderPath $startMenuTargetSubFolderPath -ShellObject $shell -CreatedCounter ([ref]$createdCount) -SkippedCounter ([ref]$skippedCount) -ErrorCounter ([ref]$errorCount)
        }
        
        # Automatically create a shortcut for the parent folder
        $normalizedFullSourcePath = (Resolve-Path $fullSourceDirPath).Path.ToLower()
        if (-not $processedFolderPaths.Contains($normalizedFullSourcePath)) {
            Write-Host "  -> Creating parent folder shortcut for '$fullSourceDirPath'"
            Create-FolderShortcut -FolderInfo (Get-Item $fullSourceDirPath) -ProgramsFolderPath $startMenuProgramsPath -ShellObject $shell -CreatedCounter ([ref]$createdCount) -SkippedCounter ([ref]$skippedCount) -ErrorCounter ([ref]$errorCount)
            $processedFolderPaths.Add($normalizedFullSourcePath)
        }
    }
    # --- HANDLE EXACT FILE PATHS ---
    else {
        $fullExePath = ""
        try {
            $fullExePath = Join-Path -Path $RootDirectory -ChildPath $normalizedEntryPath
            Write-Host "Processing exact path entry: '$entryPath' (target: '$fullExePath')"

            if (-not (Test-Path $fullExePath -PathType Leaf)) {
                Write-Warning "Target executable not found at '$fullExePath'. Skipping."
                $skippedCount++
                continue
            }

            $exeFile = Get-Item $fullExePath

            # Exact paths usually go directly into the Programs root
            $startMenuTargetFolderPath = $startMenuProgramsPath
            Write-Host "  Targeting Start Menu root folder for exact path."

            Create-AppShortcut -ExeFileInfo $exeFile -TargetFolderPath $startMenuTargetFolderPath -ShellObject $shell -CreatedCounter ([ref]$createdCount) -SkippedCounter ([ref]$skippedCount) -ErrorCounter ([ref]$errorCount)
            
            # Automatically create a shortcut for the parent folder
            $parentDirInfo = $exeFile.Directory
            $normalizedParentPath = $parentDirInfo.FullName.ToLower()
            if (-not $processedFolderPaths.Contains($normalizedParentPath)) {
                Write-Host "  -> Creating parent folder shortcut for '$($parentDirInfo.FullName)'"
                Create-FolderShortcut -FolderInfo $parentDirInfo -ProgramsFolderPath $startMenuProgramsPath -ShellObject $shell -CreatedCounter ([ref]$createdCount) -SkippedCounter ([ref]$skippedCount) -ErrorCounter ([ref]$errorCount)
                $processedFolderPaths.Add($normalizedParentPath)
            }
        }
        catch {
            Write-Error "  Failed to resolve exact path '$normalizedEntryPath' (resolved to '$fullExePath'). Error: $($_.Exception.Message)"
            $errorCount++
        }
    }
}

#endregion

#region Process StartupRelativeExePaths (Start Menu AND Startup)

Write-Host "`nProcessing Start Menu AND Startup entries from `$StartupRelativeExePaths...`n"

foreach ($entryPath in $StartupRelativeExePaths) {
    $normalizedEntryPath = $entryPath.Replace('/', '\').Trim() # Normalize slashes and trim

    # --- HANDLE WILDCARD DIRECTORY SCANS (entries ending with \*) ---
    if ($normalizedEntryPath.EndsWith('\*')) {
        $sourceDirRelativePath = $normalizedEntryPath.Substring(0, $normalizedEntryPath.Length - 2) # Remove '\*'
        $fullSourceDirPath = Join-Path -Path $RootDirectory -ChildPath $sourceDirRelativePath

        Write-Host "Processing wildcard entry: '$entryPath' (source directory: '$fullSourceDirPath')"

        if (-not (Test-Path $fullSourceDirPath -PathType Container)) {
            Write-Warning "Source directory '$fullSourceDirPath' for wildcard entry '$entryPath' not found. Skipping this entry."
            $skippedCount++ # Count as skipped attempt for this entry configuration
            continue
        }

        # Determine subfolder name for both Start Menu and Startup
        # Special case: "*" should not create a subfolder named after RootDirectory
         if ($sourceDirRelativePath -eq "" -or $sourceDirRelativePath -eq ".") {
             $startMenuTargetSubFolderPath = $startMenuProgramsPath
             $startupTargetSubFolderPath = $startupPath
             Write-Host "  Targeting Start Menu root and Startup root folders for wildcard entry '*'"
         } else {
            $sourceFolderName = Split-Path -Leaf $fullSourceDirPath
            $startMenuTargetSubFolderPath = Join-Path -Path $startMenuProgramsPath -ChildPath $sourceFolderName
            $startupTargetSubFolderPath = Join-Path -Path $startupPath -ChildPath $sourceFolderName
            Write-Host "  Targeting Start Menu subfolder: '$startMenuTargetSubFolderPath'"
            Write-Host "  Targeting Startup subfolder     : '$startupTargetSubFolderPath'"
         }

        $exeFilesInSourceDir = Get-ChildItem -Path $fullSourceDirPath -Filter "*.exe" -File -Depth 0 -ErrorAction SilentlyContinue

        if ($null -eq $exeFilesInSourceDir -or $exeFilesInSourceDir.Count -eq 0) {
            Write-Host "  No .exe files found in '$fullSourceDirPath'."
            continue
        }

        Write-Host "  Found $($exeFilesInSourceDir.Count) .exe file(s) in '$fullSourceDirPath'."
        foreach ($exeFileInstance in $exeFilesInSourceDir) {
            # Create in Start Menu Programs
            Create-AppShortcut -ExeFileInfo $exeFileInstance -TargetFolderPath $startMenuTargetSubFolderPath -ShellObject $shell -CreatedCounter ([ref]$createdCount) -SkippedCounter ([ref]$skippedCount) -ErrorCounter ([ref]$errorCount)

            # Create in Startup
            Create-AppShortcut -ExeFileInfo $exeFileInstance -TargetFolderPath $startupTargetSubFolderPath -ShellObject $shell -CreatedCounter ([ref]$createdCount) -SkippedCounter ([ref]$skippedCount) -ErrorCounter ([ref]$errorCount)
        }
        
        # Automatically create a shortcut for the parent folder (in Start Menu only)
        $normalizedFullSourcePath = (Resolve-Path $fullSourceDirPath).Path.ToLower()
        if (-not $processedFolderPaths.Contains($normalizedFullSourcePath)) {
            Write-Host "  -> Creating parent folder shortcut for '$fullSourceDirPath' (Start Menu only)"
            Create-FolderShortcut -FolderInfo (Get-Item $fullSourceDirPath) -ProgramsFolderPath $startMenuProgramsPath -ShellObject $shell -CreatedCounter ([ref]$createdCount) -SkippedCounter ([ref]$skippedCount) -ErrorCounter ([ref]$errorCount)
            $processedFolderPaths.Add($normalizedFullSourcePath)
        }
    }
    # --- HANDLE EXACT FILE PATHS ---
    else {
        $fullExePath = ""
        try {
            $fullExePath = Join-Path -Path $RootDirectory -ChildPath $normalizedEntryPath
            Write-Host "Processing exact path entry: '$entryPath' (target: '$fullExePath')"

            if (-not (Test-Path $fullExePath -PathType Leaf)) {
                Write-Warning "Target executable not found at '$fullExePath'. Skipping."
                $skippedCount++
                continue
            }

            $exeFile = Get-Item $fullExePath

            # Exact paths usually go directly into the root of the target folders
            $startMenuTargetFolderPath = $startMenuProgramsPath
            $startupTargetFolderPath = $startupPath
             Write-Host "  Targeting Start Menu root and Startup root folders for exact path."

            # Create in Start Menu Programs
            Create-AppShortcut -ExeFileInfo $exeFile -TargetFolderPath $startMenuTargetFolderPath -ShellObject $shell -CreatedCounter ([ref]$createdCount) -SkippedCounter ([ref]$skippedCount) -ErrorCounter ([ref]$errorCount)

            # Create in Startup
            Create-AppShortcut -ExeFileInfo $exeFile -TargetFolderPath $startupTargetFolderPath -ShellObject $shell -CreatedCounter ([ref]$createdCount) -SkippedCounter ([ref]$skippedCount) -ErrorCounter ([ref]$errorCount)
            
            # Automatically create a shortcut for the parent folder (in Start Menu only)
            $parentDirInfo = $exeFile.Directory
            $normalizedParentPath = $parentDirInfo.FullName.ToLower()
            if (-not $processedFolderPaths.Contains($normalizedParentPath)) {
                Write-Host "  -> Creating parent folder shortcut for '$($parentDirInfo.FullName)' (Start Menu only)"
                Create-FolderShortcut -FolderInfo $parentDirInfo -ProgramsFolderPath $startMenuProgramsPath -ShellObject $shell -CreatedCounter ([ref]$createdCount) -SkippedCounter ([ref]$skippedCount) -ErrorCounter ([ref]$errorCount)
                $processedFolderPaths.Add($normalizedParentPath)
            }
        }
        catch {
            Write-Error "  Failed to resolve exact path '$normalizedEntryPath' (resolved to '$fullExePath'). Error: $($_.Exception.Message)"
            $errorCount++
        }
    }
}

#endregion

# Summary
Write-Host "----------------------------------------"
Write-Host "Script Finished."
Write-Host "Total Shortcuts Created: $createdCount"
Write-Host "Total Paths/Files Skipped: $skippedCount (source file/dir not found or shortcut already exists at a destination)"
Write-Host "Total Errors encountered : $errorCount (failed to create shortcut/folder at a destination)"
Write-Host "----------------------------------------"
# Release COM object
if ($shell) {
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
    $shell = $null
}
pause
