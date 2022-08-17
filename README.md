# SwitchDesktop

This is my approach of implementing a poor mans i3wm for windows. It uses an autohotkey script that maps certain key combinations to the F13 and onwards buttons, and a powershell script running in the background that picks up those keys to do the actual functionality. I doubt this is helpful for anyone, but feel free to use it, and hit me up if there is anything unclear. As you notice, what this script does doesn't actually have anything to do with i3wm. Instead it results in a hopefully smooth workflow with keyboard-only phases and good mouse integration.

# Modus Operandi
Autohotkey script that spawns a powershell process in the background which does most havy lifting (on 80% of functionality). Handling of spotify done with calls to the web API. 


# Preresquites
The Powershell Modules PSVirtualDesktop and WASP (not sure if the latter is still needed in active code??) need to be installed. For Spotify Hotkeys, Spotify Secrets have to be set up such that Web-API calls can be made. Look into HowTo.txt for that. The Windows Animations "Animate Controls and elements inside windows" and "Animate windows when minimizing and maximizing" should be disabled, otherwise desktop switching and such will be painfully slow because the animations take so long.

The git repository has to be located in C:/SwitchDesktopScripts

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
Destroys the background Powershell process. Autohotkey script still keeps running (this hotkey only works really unrealiable. If restarting often, you have to kill the Windows powershell processes in the background)
## Win H
Move Focus to the topmost window to the left of the current window
## Win J
Move Focus to the topmost window to the right of the current window
## Win Middle Mouse Button
Set the mouse to the center of the currently active window
