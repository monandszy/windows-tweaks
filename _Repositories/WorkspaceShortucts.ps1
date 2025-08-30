<#
.SYNOPSIS
    Scans its local directory for folders and automates the creation of Windows shortcuts,
    Visual Studio Code workspaces, and command prompt shortcuts for them.

.DESCRIPTION
    This script is designed to be placed in a root directory containing multiple project folders.
    When run, it performs the following actions for each subfolder found:

    1.  Creates a standard folder shortcut (.lnk) in the user's Start Menu Programs folder.
        (e.g., for a folder named 'MyProject', it creates 'MyProject.lnk').
    
    2.  Creates a dedicated Visual Studio Code workspace file (.code-workspace), configured
        to open only that specific folder.
    
    3.  Stores all generated .code-workspace files in a newly created subfolder named '.workspaces'.
    
    4.  Creates a shortcut to the .code-workspace file in the Start Menu, allowing the folder
        to be launched directly in VS Code.
    
    5.  Creates a shortcut that opens the Command Prompt (cmd.exe) directly in the project
        folder's directory, named '[FolderName] (CMD).lnk'.

    The script is idempotent, meaning it will skip any items that already exist.

.EXAMPLE
    PS C:\MyProjects> .\Create-Project-Workspaces.ps1

    Assuming C:\MyProjects contains a folder 'ProjectA':
    - Creates 'C:\MyProjects\.workspaces\ProjectA.code-workspace'
    - Creates the following shortcuts in your Start Menu Programs folder:
        - 'ProjectA.lnk' (opens the folder in File Explorer)
        - 'ProjectA.code-workspace.lnk' (opens the folder in VS Code)
        - 'ProjectA (CMD).lnk' (opens Command Prompt in the ProjectA folder)

.NOTES
    - Prerequisites: PowerShell, WScript.Shell COM object (standard on Windows).
    - Permissions: Requires rights to create files/folders in the script's directory and the user's Start Menu folder.
#>
[CmdletBinding()]
param()

# --- SCRIPT CONFIGURATION ---
$WorkspacesFolderName = ".workspaces"

# --- INITIALIZATION ---
try {
    # Get the directory where the script is located. This is the root for all operations.
    $ScriptRoot = $PSScriptRoot
    if (-not $ScriptRoot) {
        Write-Error "Could not determine script root. Please run the script from a file, not the console."
        exit 1
    }

    # Define key paths
    $startMenuPath = [Environment]::GetFolderPath("Programs")
    $workspacesPath = Join-Path -Path $ScriptRoot -ChildPath $WorkspacesFolderName

    # Create the .workspaces directory if it doesn't exist
    if (-not (Test-Path $workspacesPath)) {
        Write-Host "Creating workspaces storage folder: '$workspacesPath'"
        New-Item -Path $workspacesPath -ItemType Directory -Force | Out-Null
    }

    # Create the COM object needed for creating shortcuts
    $shell = New-Object -ComObject WScript.Shell
}
catch {
    Write-Error "Initialization failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "Script Root: '$ScriptRoot'"
Write-Host "Shortcuts Target: '$startMenuPath'"
Write-Host "--------------------------------------------------"

$createdCount = 0
$skippedCount = 0
$errorCount = 0

#region Helper Functions
function Create-Shortcut {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileSystemInfo]$SourceItem, # Can be a file or a folder
        [Parameter(Mandatory = $true)]
        [string]$ShortcutDestinationFolder
    )

    try {
        $shortcutName = "$($SourceItem.Name).lnk"
        $shortcutPath = Join-Path -Path $ShortcutDestinationFolder -ChildPath $shortcutName

        if (Test-Path $shortcutPath) {
            Write-Warning "  -> Shortcut '$shortcutName' already exists. Skipping."
            $script:skippedCount++
            return
        }

        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $SourceItem.FullName
        $shortcut.WorkingDirectory = if ($SourceItem -is [System.IO.DirectoryInfo]) { $SourceItem.FullName } else { $SourceItem.DirectoryName }
        $shortcut.Save()

        Write-Host "  -> Created shortcut: '$shortcutName'"
        $script:createdCount++
    }
    catch {
        Write-Error "  -> Failed to create shortcut for '$($SourceItem.FullName)'. Error: $($_.Exception.Message)"
        $script:errorCount++
    }
}

function Create-CmdShortcut {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]$TargetFolder,
        [Parameter(Mandatory = $true)]
        [string]$ShortcutDestinationFolder
    )
    
    try {
        $shortcutName = "$($TargetFolder.Name) (CMD).lnk"
        $shortcutPath = Join-Path -Path $ShortcutDestinationFolder -ChildPath $shortcutName
        
        if (Test-Path $shortcutPath) {
            Write-Warning "  -> CMD Shortcut '$shortcutName' already exists. Skipping."
            $script:skippedCount++
            return
        }

        # $env:ComSpec is the reliable environment variable for the path to cmd.exe
        $cmdPath = $env:ComSpec

        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $cmdPath
        $shortcut.WorkingDirectory = $TargetFolder.FullName
        $shortcut.IconLocation = "$cmdPath,0"
        $shortcut.Save()
        
        Write-Host "  -> Created CMD shortcut: '$shortcutName'"
        $script:createdCount++
    }
    catch {
        Write-Error "  -> Failed to create CMD shortcut for '$($TargetFolder.FullName)'. Error: $($_.Exception.Message)"
        $script:errorCount++
    }
}
#endregion

# --- MAIN PROCESSING LOGIC ---

# Get all directories in the script's root, excluding the workspaces folder itself
$projectFolders = Get-ChildItem -Path $ScriptRoot -Directory -Exclude $WorkspacesFolderName

if ($projectFolders.Count -eq 0) {
    Write-Warning "No project folders found in '$ScriptRoot'. Nothing to do."
}

foreach ($folder in $projectFolders) {
    Write-Host "`nProcessing folder: $($folder.Name)"

    # --- Task 1: Create a standard shortcut TO the folder ---
    Create-Shortcut -SourceItem $folder -ShortcutDestinationFolder $startMenuPath

    # --- Task 2: Create a shortcut to open CMD in the folder ---
    Create-CmdShortcut -TargetFolder $folder -ShortcutDestinationFolder $startMenuPath

    # --- Task 3: Generate the .code-workspace file ---
    $workspaceFilePath = Join-Path -Path $workspacesPath -ChildPath "$($folder.Name).code-workspace"
    
    if (Test-Path $workspaceFilePath) {
        Write-Warning "  -> Workspace file '$($folder.Name).code-workspace' already exists. Skipping creation."
        $script:skippedCount++
    }
    else {
        $workspaceObject = [PSCustomObject]@{
            folders  = @([PSCustomObject]@{ path = $folder.FullName })
            settings = [PSCustomObject]@{}
        }
        try {
            $workspaceObject | ConvertTo-Json | Set-Content -Path $workspaceFilePath
            Write-Host "  -> Created workspace file: '$($folder.Name).code-workspace'"
            $script:createdCount++
        }
        catch {
            Write-Error "  -> Failed to create workspace file for '$($folder.Name)'. Error: $($_.Exception.Message)"
            $script:errorCount++
            continue # Skip trying to create a shortcut if the file failed to create
        }
    }
    
    # --- Task 4: Create a shortcut TO the workspace file ---
    $workspaceFileItem = Get-Item -Path $workspaceFilePath
    Create-Shortcut -SourceItem $workspaceFileItem -ShortcutDestinationFolder $startMenuPath
}

# --- SUMMARY AND CLEANUP ---
Write-Host "--------------------------------------------------"
Write-Host "Script Finished."
Write-Host "Total Items Created: $createdCount"
Write-Host "Total Items Skipped: $skippedCount (already existed)"
Write-Host "Total Errors: $errorCount"
Write-Host "--------------------------------------------------"

# Release the COM object
if ($shell) {
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
}

pause