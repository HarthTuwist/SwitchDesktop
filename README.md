# SwitchDesktop

This is my approach of implementing a poor mans i3wm for windows. It uses an AutoHotkey script that sends commands through Windows messages to a PowerShell script running in the background to do the actual functionality. I doubt this is helpful for anyone, but feel free to use it, and hit me up if there is anything unclear. As you notice, what this script does doesn't actually have anything to do with i3wm. Instead it results in a hopefully smooth workflow with keyboard-only phases and good mouse integration.

# Modus Operandi
Autohotkey script that spawns a powershell process in the background which does most havy lifting (on 80% of functionality). Handling of spotify done with calls to the web API. 

Uses Windows' message queue to communicate from Powershell to Autohotkey and the other way around.

On startup or reload, the wrapper asks existing Powershell backends to stop and waits up to five seconds for each receiver window to close before launching a replacement. If shutdown fails or times out, it still launches the replacement without an error dialog. Exiting the wrapper does not stop its backend; the next startup handles cleanup, or Win+Ctrl+Alt+L can stop it explicitly.

# Preresquites
The Powershell Modules PSVirtualDesktop ~~and WASP~~(WASP is not needed) need to be installed. Note that for the installments of PSVirtualDesktop I found you also need to allow execution of remote signed scripts. For Spotify Hotkeys, Spotify Secrets have to be set up such that Web-API calls can be made. Look into HowTo.txt for that. The Windows Animations "Animate Controls and elements inside windows" and "Animate windows when minimizing and maximizing" should be disabled, otherwise desktop switching and such will be painfully slow because the animations take so long.

The git repository has to be located in C:/SwitchDesktopScripts

You might have the problem that keys dont work in administrator approved (with UAC) such as the Task Manager. To let AutoHotkey interact with elevated windows, enable "Run with UI Access" in AutoHotkey Setup and launch the wrapper with `"C:\Program Files\AutoHotkey\AutoHotkeyU64_UIA.exe" "C:\SwitchDesktopScripts\SwitchDesktopWrapper.ahk"` (or equivalent). UI Access applies to AutoHotkey; it does not make its PowerShell child an administrator. See the [AutoHotkey UAC FAQ](https://www.autohotkey.com/docs/v1/FAQ.htm#uac).

#Hotkeys

## Win F
Jumps to the first(main) desktop
## Win C
Jumps to the second desktop
## Win S
Jumps to the third desktop
## Win Y
Jumps to the fourth desktop
## Win K
Pins the active window, such that it visibile on all desktops
## Win Alt K
Unpins the active window, such that it is only visible on the current desktop
## Win B
After pressing this, the next press of Win +F, C, S, Y will move the active window to the respective desktop instead of switching to it
## Win Alt C
Starts a new Firefox window on my middle screen. Lion Special key
## Win Alt F
Starts a new private Firefox window on my middle screen
## Win Alt Strg L
Stops the background PowerShell process through a Windows message. AutoHotkey still keeps running.
## Win H
Move Focus to the topmost window to the left of the current window
## Win J
Move Focus to the topmost window to the right of the current window
## Win Shift H
Send Win Shift Left (Move Window one Monitor left)
## Win Shift J
Send Win Shift Right (Move Window one Monitor right)

## Win Middle Mouse Button
Set the mouse to the center of the currently active window
