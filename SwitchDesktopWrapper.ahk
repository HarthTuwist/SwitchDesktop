;Set this such that Jumping with Win H and Win J does not make task bar blink in yellow
#WinActivateForce
;I am not sure why I am doing this anymore and whether this is necessary
#InstallKeybdHook

;Receive focus requests from our PowerShell child, including with UI Access.
OnMessage(0x802A, "FocusDesktopWindow")
DllCall("ChangeWindowMessageFilterEx", "Ptr", A_ScriptHwnd, "UInt", 0x802A, "UInt", 1, "Ptr", 0)

;Try to stop previous backends, but launch the replacement even if shutdown fails.
StopDesktopBackend()

;Setup powershell heavy lifter:

;"(get-process | ? { $_.processname -eq "powershell" } )| stop-process"  
;Process, Close, powershell.exe

;Codex suggested this. To start the window with "," seems to prevent the brief flashup (even when Terminal is default powershell terminal)
Run, powershell.exe -NoProfile -WindowStyle Hidden -File "C:\SwitchDesktopScripts\SwitchDesktops.ps1" -WrapperWindow %A_ScriptHwnd%, C:\SwitchDesktopScripts, Hide, DesktopBackendPID


SendDesktopCommand(command, notify := true)
{
    global DesktopBackendPID
    previousSetting := A_DetectHiddenWindows
    DetectHiddenWindows, On ;temporarily disable the DetectHiddenWindows policy
    target := WinExist("SwitchDesktopCommandWindow ahk_pid " DesktopBackendPID)
    sent := false
    if (target)
    {
        PostMessage, 0x8029, %command%, 0,, ahk_id %target%
        sent := !ErrorLevel
    }
    DetectHiddenWindows, %previousSetting%
    if (sent)
        return true
    return false
}

FocusDesktopWindow(senderPID, lParam, msg, hwnd)
{
    global DesktopBackendPID
    if (senderPID != DesktopBackendPID)
        return

    winget, id, list,
    loop, %id%
    {
        this_id := id%a_index%
        wingettitle, this_title, ahk_id %this_id%
        
        ;Autohotkey returns some windows with empty titles, I think the task bars. Anyways, we ignore them
        ;First hit is topmost window by the ordering of the results of winget
        if(this_title != "")
        {
            WinActivate, ahk_id %this_id%
            return
        }
    }
}

StopDesktopBackend(windowSelector := "SwitchDesktopCommandWindow ahk_exe powershell.exe")
{
    previousSetting := A_DetectHiddenWindows
    DetectHiddenWindows, On
    WinGet, backends, List, %windowSelector%
    stopped := true
    Loop, %backends%
    {
        target := backends%A_Index%
        PostMessage, 0x8029, 10, 0,, ahk_id %target%
        if (ErrorLevel)
        {
            stopped := false
            break
        }
        ;Wait for the old receiver to close before starting another backend.
        WinWaitClose, ahk_id %target%,, 5
        if (ErrorLevel)
        {
            stopped := false
            break
        }
    }
    DetectHiddenWindows, %previousSetting%
    return stopped
}





;Keys to switch desktops
<#f::
    SendDesktopCommand(1)
return

<#c::
    SendDesktopCommand(2)
return

<#s::
    SendDesktopCommand(3)
return

<#y::
    SendDesktopCommand(4)
return




#k::
    SendDesktopCommand(5)
return

#!k::
    SendDesktopCommand(6)
return

#b::
    SendDesktopCommand(7)
return

;Lion special key
#!c:: 
    SendDesktopCommand(8)
return

#!f::
    SendDesktopCommand(9)
return

#^!l::
    SendDesktopCommand(10)
return

#u::
    SendDesktopCommand(11)
return
    
;<#h::
;	Run, C:\Program Files\Mozilla Firefox\firefox.exe -foreground
;return

;<#!c::
;	Run, C:\Program Files\Mozilla Firefox\firefox.exe -private-window -foreground
;return


;Jump to the right
<#H::
    winget, activeID, ,, A
    ;wingettitle, testtitle, ahk_id %activeID%
    wingetpos, activeX, activeY, activeW, activeH, A
    ;msgBox, %testtitle%,  %activeX%, %activeY%, %activeW%
    
    winget, id, list,
    titles:=""
    titles.= "active X and W:" activeX "," activeW "`n"
    targetId := activeID
    targetXBorder := -16000
    MinImproment := 200
    leeway := 100
    loop, %id%
    {
        this_id := id%a_index%
        wingetpos, X, Y, W, H, ahk_id %this_id%
        wingettitle, this_title, ahk_id %this_id%
        wingetclass, this_class, ahk_id %targetId%
        
        ;Autohotkey returns some windows with empty titles, I think the task bars. Anyways, we ignore them
        if(this_title != "" and this_title != "SwitchDesktopWrapper.ahk" and this_class != "AutoHotkeyGUI")
        {
            ;titles.=a_index ": " this_title ";" this_class ";" X ";" W "," targetXBorder "`n" 
            if (X + W  > targetXBorder + MinImproment && X + W < activeX + leeway)
            {
                targetId = %this_id%
                targetXBorder := X + W

                ;titles.= "changed `n"
            }
        }
    }
    wingettitle, target_title, ahk_id %targetId%
    wingetclass, target_class, ahk_id %targetId%
    titles.= "`n" target_title "," target_class "`n"
    ;msgBox, % titles

    if (targetId != activeID) 
    {
        wingetpos, X, Y, W, H, ahk_id %targetId%
        Box("FF9E3B", 2, X+(W/2)-10, Y+(2*H/3)-10, X+(W/2)+10, Y+(2*H/3)+10)
        WinActivate, ahk_id %targetId%
    }
return

;jump to the right
<#J::
    winget, activeID, ,, A
    ;wingettitle, testtitle, ahk_id %activeID%
    wingetpos, activeX, activeY, activeW, activeH, A
    ;msgBox, %testtitle%,  %activeX%, %activeY%, %activeW%
    
    winget, id, list,
    titles:=""
    titles.= "active X and W:" activeX "," activeW "`n"
    targetId := activeID
    targetXBorder := 16000
    MinImproment := 200
    leeway := 100
    loop, %id%
    {
        this_id := id%a_index%
        wingetpos, X, Y, W, H, ahk_id %this_id%
        wingettitle, this_title, ahk_id %this_id%
        wingetclass, this_class, ahk_id %targetId%
        
        ;Autohotkey returns some windows with empty titles, I think the task bars. Anyways, we ignore them
        if(this_title != "" and this_title != "SwitchDesktopWrapper.ahk" and this_class != "AutoHotkeyGUI")
        {
            ;titles.=a_index ": " this_title ";" this_class ";" X ";" W "," targetXBorder "`n" 
            if (X < targetXBorder - MinImproment && X > activeX + activeW - leeway)
            {
                targetId = %this_id%
                targetXBorder := X

                ;titles.= "changed `n"
            }
        }
    }
    wingettitle, target_title, ahk_id %targetId%
    wingetclass, target_class, ahk_id %targetId%
    titles.= "`n" target_title "," target_class "`n"
    ;msgBox, % titles

    if (targetId != activeID) 
    {
        wingetpos, X, Y, W, H, ahk_id %targetId%
        Box("FF9E3B", 2, X+(W/2)-10, Y+(2*H/3)-10, X+(W/2)+10, Y+(2*H/3)+10)
        WinActivate, ahk_id %targetId%
    }
return

#MButton::
    wingetpos, activeX, activeY, activeW, activeH, A
    ;MouseMove, activeX + activeW / 2, activeY + activeH / 2, 0
    ;this can be better than wingetpos according to the documentation???
    DllCall("SetCursorPos", "int", activeX + activeW / 2, "int", activeY + activeH / 2)
    ;MouseMove, activeX , activeY , 0
return

;q::Box("FF60FF")
 
Box(Color, F, X1, Y1, X2, Y2) { ; F: Frame thickness
;	CoordMode, Mouse, Screen
;	KeyWait, LButton, D
;	MouseGetPos, X1, Y1
;	KeyWait, LButton
;	MouseGetPos, X2, Y2
	Gui, Box:New, -DPIScale -Caption +LastFound -SysMenu +ToolWindow +AlwaysOnTop +E0x20
	Gui, Box:Color,% Color
	Gui, Box:Show,% "w" (W:=X2-X1) " h" (H:=Y2-Y1) " x"X1 " y"Y1
	;WinSet, Region,% "0-0 "W "-0 "W "-"H " 0-"H " 0-0 "F "
	;-"F " "W-F "-"F " "W-F "-"H-F " "F "-"H-F " "F "-"F
	SetTimer, CloseBox, 700
}

CloseBox:
	Gui, Box:Destroy
return

#+H::
    Send #+{Left}
return

#+J::
    Send #+{Right}
return

;*AppsKey::
;    Send {RButton down}
;return

AppsKey::RAlt

;In Autohotkey this magically works as a conditional if, so the check will not just happen
;at script start but all the time be updated
#If !GetKeyState("NumLock", "T")
RAlt::RButton
#If ;Autohotkey way of endif


;*AppsKey Up::
;    Send {RButton up}
;return

;DetectHiddenWindows, On
;sendSpotifyKey(key)
;sendSpotifyKey(key)
;    {
;        if (not WinExist("ahk_exe Spotify.exe"))
;        {
;            return
;        }
;        
;        ;from https://gist.github.com/jcsteh/7ccbc6f7b1b7eb85c1c14ac5e0d65195 
;        ; Get the HWND of the Spotify main window.
;        WinGet, spotifyHwnd, ID, ahk_exe spotify.exe
;
;        ; Chromium ignores keys when it isn't focused.
;        ; Focus the document window without bringing the app to the foreground.
;        ControlFocus, Chrome_RenderWidgetHostHWND1, ahk_id %spotifyHwnd%
;        ControlSend, , %key%, ahk_id %spotifyHwnd%
;    }
;return
;
;!q::
;    sendSpotifyKey("{Space}")

;return
