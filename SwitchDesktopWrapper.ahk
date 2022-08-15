;Set this such that Jumping with Win H and Win J does not make task bar blink in yellow
#WinActivateForce
;I am not sure why I am doing this anymore and whether this is necessary
#InstallKeybdHook

;Send F22 to tell process that are still running that they should cancel
;this doesn't seem to work, but the hotkey does, strange
Send {F22 down}
Sleep 200
Send {F22 up} 

;Setup powershell heavy lifter:

;"(get-process | ? { $_.processname -eq "powershell" } )| stop-process"  
;Process, Close, powershell.exe
Run, powershell -Command "powershell -WindowStyle hidden -file  C:\SwitchDesktopScripts\SwitchDesktops.ps1"


;TODO: Can we replace this Hack with the SendMessage Function?
;LWin & f::switchDesktopByNumber(1)
<#f::
	;Send {F13 down} 
	;Sleep 30 
	;Send {F13 up}  
    ;Do not use F13m use F23 instead
	Send {F23 down} 
	Sleep 30 
	Send {F23 up}  
return

;this is called by a hook via visual basic from SwitchDesktop.ps1
F13::
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
return

<#c::
	Send {F14 down}
	Sleep 30
	Send {F14 up}  
return

<#s::
	Send {F15 down}
	Sleep 30
	Send {F15 up} 
return

<#y::
	Send {F16 down}
	Sleep 30
	Send {F16 up}  
return

#k::
	Send {F17 down}
	Sleep 30
	Send {F17 up} 
return

#!k::
	Send {F18 down}
	Sleep 30
	Send {F18 up} 
return

#b::
	Send {F19 down}
	Sleep 30
	Send {F19 up} 
return

#!c::
	Send {F20 down}
	Sleep 30
	Send {F20 up} 
return

#!f::
	Send {F21 down}
	Sleep 30
	Send {F21 up} 
return

#^!l::
	Send {F22 down}
	Sleep 30
	Send {F22 up} 
return

;F23::
;Used above
;Do not use here

#u::
	Send {F24 down}
	Sleep 30
	Send {F24 up} 
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
        
        ;Autohotkey returns some windows with empty titles, I think the task bars. Anyways, we ignore them
        if(this_title != "")
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
        
        ;Autohotkey returns some windows with empty titles, I think the task bars. Anyways, we ignore them
        if(this_title != "")
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