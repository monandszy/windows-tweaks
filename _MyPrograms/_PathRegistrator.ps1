<#
.SYNOPSIS
    Registers a pre-defined array of folders (relative to a configured root folder)
    to the Windows PATH environment variable.

.DESCRIPTION
    This script uses internally configured values for a root folder path and an array
    of relative folder paths. It resolves the full paths and adds them to either
    the User or System PATH environment variable if they are not already present
    and if the folders exist.

    Modifying the System PATH requires Administrator privileges.
    Configuration for RootFolder, RelativeFolders, Scope, and Force is done
    by editing the variables in the "SCRIPT CONFIGURATION" section below.

.NOTES
    - For changes to the PATH to be recognized by all applications (especially for System PATH),
      you might need to log out and log back in, or restart your computer.
    - New command prompt/PowerShell windows opened after the script runs will see the User PATH changes.
    - The script updates the PATH for the current PowerShell session immediately.
    - To see what the script would do without making changes, you can run it with the -WhatIf switch:
      .\YourScriptName.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param() # Parameters are now set internally

# --- SCRIPT CONFIGURATION ---
# --- EDIT THE VALUES BELOW TO CONFIGURE THE SCRIPT ---

# The absolute or relative path to the root folder.
# If relative (e.g., "."), it's resolved based on the script's current location.
# Default: $PSScriptRoot (the directory where this script is saved)
$RootFolder = (Get-Item $PSScriptRoot).FullName
# Example: $RootFolder = "C:\MyProjects\MainApp"
# Example: $RootFolder = ".\MyToolSuite" # Relative to the script's location

# An array of folder paths relative to the RootFolder.
$RelativeFolders = @(
    "Development\android\adb-platform-tools",
    "Development\android\UniversalAndroidDebloater",
    "Development\gradle-8.5\bin",
    "Development\sqlite",
    "Development\Python",
    "Development\PortableGit",
    "Development\PortableGit\bin",
    "Development\PortableGit\gcm",
    "Portable\SysInternals All",
    "Programing\vscodium-portable",
    "Development\AutoHotkey_1",
    "Development\AutoHotkey_2",
    "Development\Java\jdk-21\bin",
    "Development\ffmpeg\bin",
    "Programing\Nvim",
    "Programing\win-vind",
    "Development\msys\ucrt64\bin",
    "Development\msys",
    "Programing\android-studio-portable\app\bin",
    "Programing\android-studio-portable\data\sdk",
    "Programing\android-studio-portable\data\sdk\cmdline-tools\latest\bin",
    "Development\docker-toolbox\app"
)
# Example: $RelativeFolders = @("bin", "executables", "resources/cli")

# Specifies whether to modify the 'User' or 'System' PATH.
# Valid values: "User", "System".
# Modifying 'System' PATH requires Administrator rights.
$Scope = "System"

# If $true, the script will not prompt for confirmation before making changes
# (unless -WhatIf is used).
$ForceExecution = $false # Change to $true to bypass confirmation prompts

# --- END SCRIPT CONFIGURATION ---


# --- Internal variable for .NET API calls ---
$dotNetScope = if ($Scope -eq "System") { [System.EnvironmentVariableTarget]::Machine } else { [System.EnvironmentVariableTarget]::User }
$scopeDisplayName = $Scope # For user-facing messages

# --- Configuration & Initial Checks ---
Write-Host "Starting script execution..."
Write-Host "Configured RootFolder: $RootFolder"
Write-Host "Configured RelativeFolders: $($RelativeFolders -join ', ')"
Write-Host "Configured Scope: $scopeDisplayName (API Target: $dotNetScope)"
Write-Host "Configured ForceExecution: $ForceExecution"

# Resolve the root folder to an absolute path
try {
    $AbsoluteRootFolder = (Resolve-Path -LiteralPath $RootFolder -ErrorAction Stop).Path
    Write-Host "Resolved absolute root folder: $AbsoluteRootFolder"
    if (-not (Test-Path -LiteralPath $AbsoluteRootFolder -PathType Container)) {
        Write-Error "Root folder '$AbsoluteRootFolder' does not exist or is not a directory."
        exit 1
    }
}
catch {
    Write-Error "Error resolving root folder '$RootFolder': $($_.Exception.Message)"
    exit 1
}

# Check for Admin rights if modifying System scope
if ($dotNetScope -eq [System.EnvironmentVariableTarget]::Machine) {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "Modifying the $scopeDisplayName PATH requires Administrator privileges. Please re-run this script as Administrator."
        exit 1
    }
    Write-Host "Administrator privileges confirmed for $scopeDisplayName scope."
}

# --- Main Logic ---
$pathsToAdd = [System.Collections.Generic.List[string]]::new()
$pathsSkippedNotExist = [System.Collections.Generic.List[string]]::new()
$pathsSkippedAlreadyInPath = [System.Collections.Generic.List[string]]::new()

# Get the current PATH for the specified scope
try {
    $currentPathString = [System.Environment]::GetEnvironmentVariable("Path", $dotNetScope)
    if ($null -eq $currentPathString) { $currentPathString = "" }
    Write-Host "Original $scopeDisplayName PATH string: '$currentPathString'"
}
catch {
    Write-Error "Failed to retrieve $scopeDisplayName PATH variable: $($_.Exception.Message)"
    exit 1
}

# Split into an array, removing empty entries and trimming whitespace from each path
[string[]]$currentPathArray = @($currentPathString.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() })
Write-Host "Current $scopeDisplayName PATH, split into array and trimmed:"
$currentPathArray | ForEach-Object { Write-Host "  - '$_'" }

Write-Host "Processing relative folders:"
foreach ($relativeFolder in $RelativeFolders) {
    $fullPath = ""
    try {
        $normalizedRelativeFolder = $relativeFolder.Replace('/', '\')
        $fullPath = Join-Path -Path $AbsoluteRootFolder -ChildPath $normalizedRelativeFolder
        $fullPath = (Resolve-Path -LiteralPath $fullPath -ErrorAction SilentlyContinue).Path
    }
    catch {
        Write-Warning "Could not resolve full path for relative folder '$relativeFolder' under '$AbsoluteRootFolder'. Skipping."
        $pathsSkippedNotExist.Add($relativeFolder)
        continue
    }

    if (-not $fullPath) {
        Write-Warning "The folder for relative path '$relativeFolder' (resolved to non-existent path) under '$AbsoluteRootFolder' does not seem to exist. Skipping."
        $pathsSkippedNotExist.Add($relativeFolder)
        continue
    }
    
    $fullPath = $fullPath.Trim() # Ensure resolved path is trimmed
    Write-Host "  Relative: '$relativeFolder' -> Absolute: '$fullPath'"

    if (-not (Test-Path -LiteralPath $fullPath -PathType Container)) {
        Write-Warning "The folder '$fullPath' (from relative '$relativeFolder') does not exist or is not a directory. Skipping."
        $pathsSkippedNotExist.Add($fullPath)
        continue
    }

    $isAlreadyInPath = $false
    foreach($existingEntry in $currentPathArray) { # $currentPathArray elements are already trimmed
        if ($existingEntry.TrimEnd('\') -eq $fullPath.TrimEnd('\')) {
            $isAlreadyInPath = $true
            break
        }
    }

    if ($isAlreadyInPath) {
        Write-Host "  Path '$fullPath' is already in the $scopeDisplayName PATH (case-insensitive, ignoring trailing slashes). Skipping."
        $pathsSkippedAlreadyInPath.Add($fullPath)
    } else {
        Write-Host "  Path '$fullPath' will be considered for addition to the $scopeDisplayName PATH." -ForegroundColor Yellow
        $pathsToAdd.Add($fullPath)
    }
}

# --- Apply Changes ---
if ($pathsToAdd.Count -eq 0) {
    Write-Host "No new paths to add to the $scopeDisplayName PATH."
    # Fall through to report skipped paths
} else {
    Write-Host "Preparing to construct the new PATH string."
    
    # 1. Combine current paths and new paths into a single list
    $combinedPathList = [System.Collections.Generic.List[string]]::new()
    $combinedPathList.AddRange($currentPathArray) # Already trimmed
    $combinedPathList.AddRange($pathsToAdd)     # Already trimmed

    Write-Host "Combined list of all path segments (current and new to add):"
    $combinedPathList | ForEach-Object { Write-Host "  - Combined: '$_'" }

    # 2. Filter for uniqueness (case-insensitive for strings by default with Select-Object)
    #    All elements should already be trimmed.
    $uniqueFinalPaths = $combinedPathList | Select-Object -Unique

    Write-Host "List of unique path segments (after Select-Object -Unique):"
    $uniqueFinalPaths | ForEach-Object { Write-Host "  - Unique: '$_'" }

    # 3. Join to form the new PATH string
    $newPathString = $uniqueFinalPaths -join ';'
    
    # Handle edge case: if the only path was empty string, $newPathString could be empty or just a semicolon.
    # This ensures that if all paths were effectively empty, the result is an empty string.
    if ($newPathString -eq ';' -and $uniqueFinalPaths.Count -le 1) {
        # This can happen if $uniqueFinalPaths was @("") or @("", "")
        # If uniqueFinalPaths was @(""), -join ';' is "", so this isn't hit.
        # If uniqueFinalPaths was @("", ""), -join ';' is ";".
        # If after all processing, the path is just a semicolon (from joining two empty strings that somehow passed filters),
        # or if it's empty, treat as empty.
        $newPathString = ($uniqueFinalPaths | Where-Object {$_ -ne ""}) -join ';'
        if ($newPathString -eq $null) {$newPathString = ""} # ensure it's not null
    }


    Write-Host "Final new PATH string constructed: '$newPathString'"

    if ($ForceExecution -or $PSCmdlet.ShouldProcess("PATH environment variable (Scope: $scopeDisplayName)", "Set to `"$newPathString`"")) {
        try {
            [System.Environment]::SetEnvironmentVariable("Path", $newPathString, $dotNetScope)
            Write-Host "Successfully updated the $scopeDisplayName PATH environment variable." -ForegroundColor Green

            # Update PATH for the current PowerShell session
            $userPathSys = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
            $machinePathSys = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
            
            $sessionPathArray = @()
            if (-not [string]::IsNullOrEmpty($userPathSys)) {
                $sessionPathArray += $userPathSys.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() }
            }
            if (-not [string]::IsNullOrEmpty($machinePathSys)) {
                $sessionPathArray += $machinePathSys.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() }
            }
            
            $env:PATH = ($sessionPathArray | Select-Object -Unique) -join ';' # Unique again for session
            Write-Host "Current PowerShell session PATH updated to: $($env:PATH)"
            Write-Host "Current PowerShell session's PATH has also been updated."

            if ($dotNetScope -eq [System.EnvironmentVariableTarget]::Machine) {
                Write-Warning "$scopeDisplayName (System) PATH was updated. A system restart or logging out and back in may be required for all applications to see the change."
            } else {
                Write-Host "$scopeDisplayName PATH was updated. New command prompts or PowerShell windows will see the change. Some running applications might need a restart."
            }

            Write-Host "`nAdded Paths (these were new):" -ForegroundColor Cyan
            $pathsToAdd | ForEach-Object { Write-Host "- $_" } # These are the paths that were not duplicates of existing ones

        }
        catch {
            Write-Error "Failed to set the $scopeDisplayName PATH environment variable: $($_.Exception.Message)"
            Write-Error "Original $scopeDisplayName PATH was: $currentPathString"
            Write-Error "Attempted to set to: $newPathString"
            exit 1
        }
    } else {
        Write-Host "Operation cancelled by user or due to -WhatIf."
        Write-Host "The $scopeDisplayName PATH environment variable was NOT changed."
        Write-Host "The new PATH string would have been: '$newPathString'"
        Write-Host "The following paths would have been effectively added (if not already present in a different form):"
        $pathsToAdd | ForEach-Object { Write-Host "- $_" }
    }
}

if ($pathsSkippedNotExist.Count -gt 0) {
    Write-Warning "`nThe following specified relative folders did not resolve to existing directories and were skipped:"
    $pathsSkippedNotExist | ForEach-Object { Write-Warning "- $_" }
}
if ($pathsSkippedAlreadyInPath.Count -gt 0) {
    Write-Information "`nThe following resolved folders were already present in the $scopeDisplayName PATH and were skipped for addition:"
    $pathsSkippedAlreadyInPath | ForEach-Object { Write-Information "- $_" }
}

Write-Host "Script execution finished."
pause