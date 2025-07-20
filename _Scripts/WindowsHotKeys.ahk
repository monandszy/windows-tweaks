#Requires AutoHotkey v2.0
#NoTrayIcon
#SingleInstance
If !A_IsAdmin
    Run('*RunAs ".\WindowsHotKeys.exe"')

; Run FlowLauncher on Win Key
~LWin::Send "{Blind}{VKFF}"    ; prevents Start menu from showing if pressed by itself while allowing it as a hotkey modifier
LWin Up::{
    if (A_PriorKey = "LWin") { ; check if Lwin was pressed down, then up without other keys pressed in between.
        Send "^{F23}" ; Control + F23
    }
}
~RWin::Send "{Blind}{VKFF}"
RWin Up::{
    if (A_PriorKey = "RWin") {
        Send "^{F23}"
    }
}

; Run librewolf browser on Win+F
hpath := EnvGet("USERPROFILE")
#f::Run hpath "\_MyPrograms\Portable\LibreWolf Portable\LibreWolf-Portable.exe"