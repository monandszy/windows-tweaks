<#
.SYNOPSIS
    Creates shortcuts for all files found in _Functional and _Functional\Startup folders,
    placing them in the Start Menu Programs and Startup folders respectively.
    Files from _Functional\Startup are duplicated in both the Startup folder AND
    the Programs\_Functional folder.

.DESCRIPTION
    This script scans the specified `$RootDirectory` for the following subfolders:
    - `_Functional`: All files in this folder will get a shortcut placed in a
      `_Functional` subfolder within the user's Start Menu Programs directory.
    - `_Functional\Startup`: All files in this folder will get a shortcut placed
      directly within the user's Start Menu Startup directory.
      **Additionally, shortcuts for files in `_Functional\Startup` will ALSO be**
      **placed in the `_Functional` subfolder within the user's Start Menu Programs**
      **directory.**

    Shortcuts are created for *all file types* found directly within these source folders
    (non-recursive scan). The shortcut name includes the original file extension.

    General behavior:
    - Uses `$RootDirectory` (or current location) as the base.
    - Uses WScript.Shell COM object.
    - Skips if a shortcut with the same name already exists in its target Start Menu location.
    - Creates the target `_Functional` subfolder in Start Menu Programs if it doesn't exist.
    - Provides console output and a final summary.

.PARAMETER RootDirectory
    The root directory for resolving the _Functional and _Functional\Startup paths.
    Defaults to current location.

.EXAMPLE
    PS C:\> .\Create-FunctionalShortcuts.ps1 -RootDirectory "D:\MyPortableApps"

    If "D:\MyPortableApps\_Functional" contains "myscript.ps1":
    - Shortcut created in `C:\Users\CurrentUser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\_Functional\myscript.ps1.lnk`.

    If "D:\MyPortableApps\_Functional\Startup" contains "monitor.bat":
    - Shortcut created in `C:\Users\CurrentUser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\monitor.bat.lnk`.
    - **Additional** shortcut created in `C:\Users\CurrentUser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\_Functional\monitor.bat.lnk`.

.NOTES
    Prerequisites: PowerShell, WScript.Shell COM object.
    Permissions: Required to create files and directories in the user's Start Menu folders.
#>
param(
    [string]$RootDirectory = (Get-Location).Path
)

# Get start menu paths
try {
    $startMenuProgramsPath = [Environment]::GetFolderPath("Programs")
    $startMenuStartupPath  = [Environment]::GetFolderPath("Startup")

    if (-not (Test-Path $startMenuProgramsPath -PathType Container)) {
         Write-Error "FATAL: Start Menu Programs directory '$startMenuProgramsPath' not found or inaccessible."
         exit 1
    }
     if (-not (Test-Path $startMenuStartupPath -PathType Container)) {
         Write-Error "FATAL: Start Menu Startup directory '$startMenuStartupPath' not found or inaccessible."
         exit 1
    }

    Write-Host "Target Start Menu Programs directory: '$startMenuProgramsPath'"
    Write-Host "Target Start Menu Startup directory : '$startMenuStartupPath'"

} catch {
    Write-Error "FATAL: Could not determine Start Menu paths. Error: $($_.Exception.Message)"
    exit 1
}

# Create WScript.Shell COM object
$shell = $null
try {
    $shell = New-Object -ComObject WScript.Shell
}
catch {
    Write-Error "FATAL: Failed to create WScript.Shell COM object. Error: $($_.Exception.Message)"
    exit 1
}

# Initialize counters
$createdCount = 0
$skippedCount = 0
$errorCount = 0

# --- Process _Functional folder for Start Menu Programs ---
Write-Host ""
Write-Host "--- Processing _Functional Folder for Start Menu Programs ---"

$functionalFolderRelativePath = "_Functional"
$fullFunctionalFolderPath = Join-Path -Path $RootDirectory -ChildPath $functionalFolderRelativePath

# Target location in Start Menu Programs - Create a subfolder named "_Functional"
$targetFunctionalProgramsPath = Join-Path -Path $startMenuProgramsPath -ChildPath "_Functional"

# Ensure the target subfolder in Start Menu Programs exists
if (-not (Test-Path $targetFunctionalProgramsPath -PathType Container)) {
    Write-Host "Target directory '$targetFunctionalProgramsPath' for shortcuts does not exist. Creating..."
    try {
        $null = New-Item -Path $targetFunctionalProgramsPath -ItemType Directory -ErrorAction Stop
        Write-Host "Successfully created directory: '$targetFunctionalProgramsPath'"
    }
    catch {
        Write-Error "Failed to create target directory '$targetFunctionalProgramsPath'. Error: $($_.Exception.Message). Shortcuts for Programs\_Functional will be skipped."
        $errorCount++
        $canWriteToFunctionalPrograms = $false
    }
} else {
     $canWriteToFunctionalPrograms = $true
}


# Process files from _Functional folder (only if target directory exists)
if (-not (Test-Path $fullFunctionalFolderPath -PathType Container)) {
    Write-Warning "Source folder '$fullFunctionalFolderPath' not found. Skipping processing for Start Menu Programs."
    $skippedCount++ 
} elseif ($canWriteToFunctionalPrograms) {
    $filesInFunctional = Get-ChildItem -Path $fullFunctionalFolderPath -File -Depth 0 -ErrorAction SilentlyContinue

    if ($null -eq $filesInFunctional -or $filesInFunctional.Count -eq 0) {
        Write-Host "No files found in '$fullFunctionalFolderPath'."
    } else {
        Write-Host "Found $($filesInFunctional.Count) file(s) in '$fullFunctionalFolderPath'. Creating shortcuts in '$targetFunctionalProgramsPath'."
        foreach ($file in $filesInFunctional) {
            $shortcutName = "$($file.BaseName)$($file.Extension).lnk" 
            $shortcutPath = Join-Path -Path $targetFunctionalProgramsPath -ChildPath $shortcutName

            try {
                if (Test-Path $shortcutPath) {
                    Write-Warning "  Programs\_Functional shortcut '$shortcutPath' already exists. Skipping."
                    $skippedCount++
                    continue
                }

                $shortcut = $shell.CreateShortcut($shortcutPath)
                $shortcut.TargetPath = $file.FullName
                $shortcut.WorkingDirectory = $file.DirectoryName
                $shortcut.Save()
                Write-Host "  Created Programs\_Functional shortcut: '$shortcutPath'"
                $createdCount++
            }
            catch {
                Write-Error "  Failed to create Programs\_Functional shortcut for '$($file.FullName)' at '$shortcutPath'. Error: $($_.Exception.Message)"
                $errorCount++
            }
        }
    }
} else {
    Write-Warning "Skipping shortcut creation from '$fullFunctionalFolderPath' because the target directory '$targetFunctionalProgramsPath' could not be created."
}


# Process _Functional\Startup folder for Start Menu Startup and Start Menu Programs
Write-Host "" 
Write-Host "--- Processing _Functional\Startup Folder for Start Menu Startup AND Programs ---"

$functionalStartupFolderRelativePath = "_Functional\Startup"
$fullFunctionalStartupFolderPath = Join-Path -Path $RootDirectory -ChildPath $functionalStartupFolderRelativePath

if (-not (Test-Path $fullFunctionalStartupFolderPath -PathType Container)) {
    Write-Warning "Source folder '$fullFunctionalStartupFolderPath' not found. Skipping processing."
    $skippedCount++ 
} else {
    $filesInFunctionalStartup = Get-ChildItem -Path $fullFunctionalStartupFolderPath -File -Depth 0 -ErrorAction SilentlyContinue

    if ($null -eq $filesInFunctionalStartup -or $filesInFunctionalStartup.Count -eq 0) {
        Write-Host "No files found in '$fullFunctionalStartupFolderPath'."
    } else {
        Write-Host "Found $($filesInFunctionalStartup.Count) file(s) in '$fullFunctionalStartupFolderPath'."
        $targetFunctionalStartupPath = $startMenuStartupPath
        Write-Host "Creating shortcuts in Start Menu Startup: '$targetFunctionalStartupPath'"
        foreach ($file in $filesInFunctionalStartup) {
            $shortcutName = "$($file.BaseName)$($file.Extension).lnk"
            $shortcutPath = Join-Path -Path $targetFunctionalStartupPath -ChildPath $shortcutName

            try {
                if (Test-Path $shortcutPath) {
                    Write-Warning "  Startup shortcut '$shortcutPath' already exists. Skipping."
                    $skippedCount++
                    continue
                }

                $shortcut = $shell.CreateShortcut($shortcutPath)
                $shortcut.TargetPath = $file.FullName
                $shortcut.WorkingDirectory = $file.DirectoryName
                $shortcut.Save()
                Write-Host "  Created Startup shortcut: '$shortcutPath'"
                $createdCount++
            }
            catch {
                Write-Error "  Failed to create Startup shortcut for '$($file.FullName)' at '$shortcutPath'. Error: $($_.Exception.Message)"
                $errorCount++
            }
        } 

        # also create shortcuts in Start Menu Programs\_Functional

        if ($canWriteToFunctionalPrograms) {
            Write-Host "Also creating shortcuts in Start Menu Programs\_Functional: '$targetFunctionalProgramsPath'"
            foreach ($file in $filesInFunctionalStartup) {
                $shortcutName = "$($file.BaseName)$($file.Extension).lnk" 
                $shortcutPath = Join-Path -Path $targetFunctionalProgramsPath -ChildPath $shortcutName

                try {
                    if (Test-Path $shortcutPath) {
                        Write-Warning "  Programs\_Functional shortcut '$shortcutPath' (from Startup folder) already exists. Skipping."
                        $skippedCount++
                        continue
                    }

                    $shortcut = $shell.CreateShortcut($shortcutPath)
                    $shortcut.TargetPath = $file.FullName
                    $shortcut.WorkingDirectory = $file.DirectoryName
                    $shortcut.Save()
                    Write-Host "  Created Programs\_Functional shortcut (from Startup folder): '$shortcutPath'"
                    $createdCount++
                }
                catch {
                    Write-Error "  Failed to create Programs\_Functional shortcut (from Startup folder) for '$($file.FullName)' at '$shortcutPath'. Error: $($_.Exception.Message)"
                    $errorCount++
                }
            }
        } else {
             Write-Warning "Skipping creation of Programs\_Functional shortcuts from '$fullFunctionalStartupFolderPath' because the target directory '$targetFunctionalProgramsPath' could not be created."
        }

    }
} 


# Summary
Write-Host "----------------------------------------"
Write-Host "Script Finished."
Write-Host "Total Shortcuts Created: $createdCount"
Write-Host "Total Items Skipped: $skippedCount (source folder not found or shortcut exists)"
Write-Host "Total Errors encountered : $errorCount"
Write-Host "----------------------------------------"
Write-Host "Note: Files from _Functional\Startup are placed in *both* Start Menu Startup and Start Menu Programs\_Functional."


# Release COM object
if ($shell) {
    Write-Host "Releasing COM object..."
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
    $shell = $null
}

# Provide path to the user Start Menu folders
Write-Host "Check your shortcuts in:"
Write-Host "  Start Menu Programs\_Functional: '$startMenuProgramsPath\_Functional'"
Write-Host "  Start Menu Startup           : '$startMenuStartupPath'"
pause