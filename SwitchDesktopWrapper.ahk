;Setup powershell heavy lifter:

;"(get-process | ? { $_.processname -eq "powershell" } )| stop-process"  
;Process, Close, powershell.exe
Run, powershell -Command "powershell -WindowStyle hidden -file  C:\SwitchDesktopScripts\SwitchDesktops.ps1"
#InstallKeybdHook

;LWin & f::switchDesktopByNumber(1)
<#f::
	Send {F13 down} 
	Sleep 30 
	Send {F13 up}  
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

<#h::
	Run, C:\Program Files\Mozilla Firefox\firefox.exe -foreground
return

<#!c::
	Run, C:\Program Files\Mozilla Firefox\firefox.exe -private-window -foreground
return
;LWin & c::switchDesktopByNumber(2)
;LWin & s::switchDesktopByNumber(3)
;LWin & y::switchDesktopByNumber(4)