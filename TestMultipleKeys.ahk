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

;Jump to the left

<#H::
    winget, activeID, ,, A
    wingettitle, testtitle, ahk_id %activeID%
    wingetpos, activeX, activeY, activeW, activeH, A
    ;msgBox, %testtitle%,  %activeX%, %activeY%, %activeW%
    ;get active window
    
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
        ; X + W rechte kante X linke Kante
        if(this_title != "")
        {
            titles.=a_index ": " this_title ";" this_class ";" X ";" W "," targetXBorder "`n" 
            if (X + W  > targetXBorder + MinImproment && X + W < activeX + leeway)
            {
                targetId = %this_id%
                targetXBorder := X + W

                titles.= "changed `n"
               ; msgBox, changed
            }
            ;msgBox, %this_title%, %targetXBorder%, %X%, %W%
        }
           
        ;msgBox, %this_title%
;       {
;            if (X + W  > targetXBorder && X + W < activeX)
;       }
    }
    wingettitle, target_title, ahk_id %targetId%
    wingetclass, target_class, ahk_id %targetId%
    titles.= "`n" target_title "," target_class "`n"
    ;msgBox, % titles
   
   ;ControlFocus ,, ahk_id %targetId%
    WinActivate, ahk_id %targetId%
   ; msgBox, ahk_id %targetId%, %target_title%, %target_class%
    










/*     winget, id, list,
    titles:=""
    loop, %id%
    {
        this_id := id%a_index%
        wingetclass, this_class, ahk_id %this_id%
        wingettitle, this_title, ahk_id %this_id%
        titles.=a_index ": " this_title ";" this_class "`n" 
    }
    msgBox, % titles  */

return