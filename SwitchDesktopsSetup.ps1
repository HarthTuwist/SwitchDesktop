<# function Get-ChildWindow{
[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline = $true, ValueFromPipelinebyPropertyName = $true)]
    [ValidateNotNullorEmpty()]
    [System.IntPtr]$MainWindowHandle
)

BEGIN{
    function Get-WindowName($hwnd) {
        $len = [apifuncs]::GetWindowTextLength($hwnd)
        if($len -gt 0){
            $sb = New-Object text.stringbuilder -ArgumentList ($len + 1)
            $rtnlen = [apifuncs]::GetWindowText($hwnd,$sb,$sb.Capacity)
            $sb.tostring()
        }
    }

    if (("APIFuncs" -as [type]) -eq $null){
        Add-Type  @"
        using System;
        using System.Runtime.InteropServices;
        using System.Collections.Generic;
        using System.Text;
        public class APIFuncs
          {
            [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern int GetWindowText(IntPtr hwnd,StringBuilder lpString, int cch);

            [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
            public static extern IntPtr GetForegroundWindow();

            [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
            public static extern Int32 GetWindowThreadProcessId(IntPtr hWnd,out Int32 lpdwProcessId);

            [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
            public static extern Int32 GetWindowTextLength(IntPtr hWnd);

            [DllImport("user32")]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool EnumChildWindows(IntPtr window, EnumWindowProc callback, IntPtr i);
            public static List<IntPtr> GetChildWindows(IntPtr parent)
            {
               List<IntPtr> result = new List<IntPtr>();
               GCHandle listHandle = GCHandle.Alloc(result);
               try
               {
                   EnumWindowProc childProc = new EnumWindowProc(EnumWindow);
                   EnumChildWindows(parent, childProc,GCHandle.ToIntPtr(listHandle));
               }
               finally
               {
                   if (listHandle.IsAllocated)
                       listHandle.Free();
               }
               return result;
           }
            private static bool EnumWindow(IntPtr handle, IntPtr pointer)
           {
               GCHandle gch = GCHandle.FromIntPtr(pointer);
               List<IntPtr> list = gch.Target as List<IntPtr>;
               if (list == null)
               {
                   throw new InvalidCastException("GCHandle Target could not be cast as List<IntPtr>");
               }
               list.Add(handle);
               //  You can modify this to check to see if you want to cancel the operation, then return a null here
               return true;
           }
            public delegate bool EnumWindowProc(IntPtr hWnd, IntPtr parameter);
           }
"@
        }
}

PROCESS{
    foreach ($child in ([apifuncs]::GetChildWindows($MainWindowHandle))){
        Write-Output (,([PSCustomObject] @{
            MainWindowHandle = $MainWindowHandle
            ChildId = $child
            ChildTitle = (Get-WindowName($child))
        }))
    }
}
}

 #>

#from https://superuser.com/questions/1328345/find-all-window-titles-of-application-through-command-line
Add-Type  @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;    
    public class Win32 {
        public delegate void ThreadDelegate(IntPtr hWnd, IntPtr lParam);
        
        [DllImport("user32.dll")]
        public static extern bool EnumThreadWindows(int dwThreadId, 
            ThreadDelegate lpfn, IntPtr lParam);
        
        [DllImport("user32.dll", CharSet=CharSet.Auto, SetLastError=true)]
        public static extern int GetWindowText(IntPtr hwnd, 
            StringBuilder lpString, int cch);
        
        [DllImport("user32.dll", CharSet=CharSet.Auto, SetLastError=true)]
        public static extern Int32 GetWindowTextLength(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool IsIconic(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool IsWindowVisible(IntPtr hWnd);

        public static string GetTitle(IntPtr hWnd) {
            var len = GetWindowTextLength(hWnd);
            StringBuilder title = new StringBuilder(len + 1);
            GetWindowText(hWnd, title, title.Capacity);
            return title.ToString();
        }
    }
"@
  # $OriginalWindows = New-Object System.Collections.ArrayList
    <# Get-Process firefox | Where { $_.MainWindowTitle } | foreach {
    $_.Threads.ForEach({
        [void][Win32]::EnumThreadWindows($_.Id, {
            param($hwnd, $lparam)
            if ([Win32]::IsIconic($hwnd) -or [Win32]::IsWindowVisible($hwnd)) {
                $windows.Add([Win32]::GetTitle($hwnd))
            }}, 0)
        })} #>



<#     Get-Process firefox | Where { $_.MainWindowTitle} | foreach {
    $_.Threads.ForEach({
        [void][Win32]::EnumThreadWindows($_.Id, {
            param($hwnd, $lparam)
            if ([Win32]::IsIconic($hwnd) -or [Win32]::IsWindowVisible($hwnd)) {
                $OriginalWindows.Add($hwnd)
            }}, 0)
        })} #>


function WaitFirefoxOpen()
{
    param (
        $Arguments
    )

   $OriginalWindows = New-Object System.Collections.ArrayList
    <# Get-Process firefox | Where { $_.MainWindowTitle } | foreach {
    $_.Threads.ForEach({
        [void][Win32]::EnumThreadWindows($_.Id, {
            param($hwnd, $lparam)
            if ([Win32]::IsIconic($hwnd) -or [Win32]::IsWindowVisible($hwnd)) {
                $windows.Add([Win32]::GetTitle($hwnd))
            }}, 0)
        })} #>
    $FireFoxAllProcess = Get-Process firefox -ErrorAction SilentlyContinue #do not throw errors if we do not find FF
    
    if($FireFoxAllProcess)
    {
        $FireFoxAllProcess | Where { $_.MainWindowTitle} | foreach {
        $_.Threads.ForEach({
            [void][Win32]::EnumThreadWindows($_.Id, {
                param($hwnd, $lparam)
                if ([Win32]::IsIconic($hwnd) -or [Win32]::IsWindowVisible($hwnd)) {
                    $OriginalWindows.Add($hwnd)
                }}, 0)
            })}
    }

    Start-Process "C:\Program Files\Mozilla Firefox\firefox.exe" -ArgumentList $Arguments

    do
    {  
        $NewWindows = New-Object System.Collections.ArrayList
        
        #find the new windows exactly like the original ones
        Get-Process firefox | Where { $_.MainWindowTitle} | foreach {
        $_.Threads.ForEach({
        [void][Win32]::EnumThreadWindows($_.Id, {
            param($hwnd, $lparam)
            if ([Win32]::IsIconic($hwnd) -or [Win32]::IsWindowVisible($hwnd)) {
                $NewWindows.Add($hwnd)
            }}, 0)
        })}


       
        foreach ($newWind in $NewWindows) {
            $FoundNewWindow = $true
            foreach ($orgWind in $OriginalWindows){
                if($orgWind -eq $newWind)
                {
                    $FoundNewWindow = $false
                }
            }

            if($FoundNewWindow)
            {
                Write-Host FoundWindow $newWind -ForegroundColor White

                $OriginalWindows = @()
                $OriginalWindows = $OriginalWindows + $NewWindows
                return $newWind
            }
        }
        Write-Host $NewWindows -ForegroundColor Green
        Write-Host $OriginalWindows -ForegroundColor DarkRed
        Start-Sleep -Milliseconds 50


    } while($true)
}

    Try { 
        [void][Window]
    } Catch {
    Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        public class Window {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetWindowRect(
            IntPtr hWnd, out RECT lpRect);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public extern static bool MoveWindow( 
            IntPtr handle, int x, int y, int width, int height, bool redraw);

        [DllImport("user32.dll")] 
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ShowWindow(
            IntPtr handle, int state);
        }
        public struct RECT
        {
        public int Left;        // x position of upper-left corner
        public int Top;         // y position of upper-left corner
        public int Right;       // x position of lower-right corner
        public int Bottom;      // y position of lower-right corner
        }
"@
    }


function GetWindowForSetup ()
{   
        param (
        $Program
    )

    Write-Host "GetWindowForSetup" $program -ForegroundColor DarkGreen

    $processList = Get-Process $Program -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle -ne ""}
    Write-Host $processList -ForegroundColor Green
    If  ($processList)
    {
        $procToReturn = $processList[0]
    }
    else
    {
        if($Program -eq "thunderbird")
        {
            $procToReturn = Start-Process  "C:\Program Files (x86)\Mozilla Thunderbird\thunderbird.exe" -PassThru
        }

        if($Program -eq "signal")
        {
            $procToReturn = Start-Process  "C:\Users\offen\AppData\Local\Programs\signal-desktop\Signal.exe" -PassThru
        }
        
        if($Program -eq "spotify")
        {
            $procToReturn = Start-Process spotify -PassThru
        }
        
        if($Program -eq "discord")
        {
            $procToReturn = Start-Process "C:\Users\offen\AppData\Local\Discord\Update.exe" -ArgumentList  "--processStart Discord.exe" -PassThru
        }


    }

    #wait for the process to open the window/have a MainWindowHandle #ToDo: untested
    $iterations = 0
    do{
        #$procToReturn.WaitForInputIdle
       # $procToReturn.Refresh() 
       $FoundProgram = Get-Process $Program -ErrorAction SilentlyContinue | Where { $_.MainWindowTitle}

    if ($FoundProgram)
    {
          Write-Host "Proc to return" $FoundProgram -ForegroundColor Green
            Write-Host "Proc to return MainWindowHandle" $FoundProgram.MainWindowHandle -ForegroundColor Green
            #Write-Host "Proc to return MainWindowHandle" $procToReturn.MainWindowHandle -ForegroundColor Green

            return $FoundProgram.MainWindowHandle
    }
    
        Start-Sleep -Milliseconds 75
    } while ($iterations -lt 300)


  }



#[Window]::MoveWindow($handle, -1928, 32, 1936, 1056, $True) move to left monitor
#[Window]::MoveWindow($handle, -8, 32, 1936, 1056, $True) move to middle monitor


#Start-Process "C:\Program Files\Mozilla Firefox\firefox.exe" -ArgumentList "-private-window"


#firefox windows
$PinnedFF = WaitFirefoxOpen -Arguments "-new-window https://www.twitch.tv/directory/game/Dota%202" 
$PinnedFF | Move-Window (Get-Desktop 0) 
Pin-Window $PinnedFF
[Window]::MoveWindow($PinnedFF, -1928, 32, 1936, 1056, $True)


$PinnedFFprivate = WaitFirefoxOpen -Arguments "-private-window" 
$PinnedFFprivate | Move-Window (Get-Desktop 0) 
Pin-Window $PinnedFFprivate
[Window]::MoveWindow($PinnedFFprivate, -1928, 32, 1936, 1056, $True)


$FirefoxMusic = WaitFirefoxOpen -Arguments "-private-window"
$FirefoxMusic | Move-Window (Get-Desktop 2)
[Window]::MoveWindow($FirefoxMusic, -8, 32, 1936, 1056, $True)


$FirefoxMessenger = WaitFirefoxOpen -Arguments "web.whatsapp.com web.telegram.org" 
$FirefoxMessenger| Move-Window (Get-Desktop 3)
[Window]::MoveWindow($FirefoxMessenger, -8, 32, 1936, 1056, $True)



GetWindowForSetup -Program signal | Move-Window (Get-Desktop 3)     
GetWindowForSetup -Program thunderbird | Move-Window (Get-Desktop 3) 
GetWindowForSetup -Program discord | Move-Window (Get-Desktop 3) 
GetWindowForSetup -Program spotify | Move-Window (Get-Desktop 2) 

#$processNames = @('Firefox','Oranges','Bananas')

<# 
Get-Process firefox | Where { $_.MainWindowTitle} | foreach {
    $_.Threads.ForEach({
        [void][Win32]::EnumThreadWindows($_.Id, {
            param($hwnd, $lparam)
            if ([Win32]::IsIconic($hwnd) -or [Win32]::IsWindowVisible($hwnd)) {
                $windows.Add($hwnd)
            }}, 0)
        })}
Write-Output $windows #>


#(Get-Process firefox)[0] | Where-Object {$_.ProcessName -eq 'firefox'} | Get-ChildWindow


<# 

#Get-Desktop 3 | Switch-Desktop

#&"C:\Program Files\Mozilla Firefox\firefox.exe" web.whatsapp.com web.telegram.org

$processList = Get-Process thunderbird -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle -ne ""}
Write-Host $processList -ForegroundColor Green
If  ($processList)
{
    #$procFFChat = Start-Process  "C:\Program Files\Mozilla Firefox\firefox.exe" -ArgumentList "web.whatsapp.com web.telegram.org" -PassThru
    $procFFChat = $processList[0]
}
else
{
    #$procFFChat = Start-Process  "C:\Users\offen\AppData\Local\Programs\signal-desktop\Signal.exe" -PassThru
    $procFFChat = Start-Process  "C:\Program Files (x86)\Mozilla Thunderbird\thunderbird.exe" -PassThru
}

#wait for the process to open the window/have a MainWindowHandle #ToDo: untested
$iterations = 0
do{
    $procFFChat.Refresh() 
    if ($procFFChat.MainWindowHandle -ne 0)
   {
        break
   }
   
    Start-Sleep -Milliseconds 15
} while ($iterations -lt 300)


Write-Host "Proc FF Chat" $procFFChat -ForegroundColor Green
Write-Host "Proc FF Chat MainWindowHandle" (Get-Process -Id $procFFChat.Id).MainWindowHandle -ForegroundColor Green
#Write-Host "GetProcess" (Get-Process -Id $procFFChat.Id)-ForegroundColor Green
(Get-Process -Id $procFFChat.Id).MainWindowHandle | Move-Window (Get-Desktop 3)

 #>
# Get-Process firefox | Where-Object {$_.MainWindowTitle -ne ""} | Select-Object MainWindowTitle

# &"C:\Program Files\Mozilla Firefox\firefox.exe" -new-window google.com -new-window yahoo.com

<# $procFFChat = Start-Process  "C:\Program Files\Mozilla Firefox\firefox.exe" -ArgumentList "web.whatsapp.com web.telegram.org" -PassThru

$procFFChat.WaitForInputIdle 

(Get-Process -Id $procFFChat.Id).MainWindowHandle | Move-Window (Get-Desktop 3)
 #>

 #ToDo: Wie kann ich verschiedene Firefox Windows handeln und an verschiedene Orte verschieben?