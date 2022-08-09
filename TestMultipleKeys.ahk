;Use this as to prevent yellow flashing of taskbar when jumping through windows
#WinActivateForce



; <F1::
;  Test := true 
;return

;C::
;    if(Test)
;    {
;        MsgBox "F2 pressed"
;    }
;    else
;    {
;	    Send {c down}
;    }
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