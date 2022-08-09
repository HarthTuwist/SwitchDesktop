$host.ui.RawUI.WindowTitle = "SwitchDesktopsPowershell"
Import-Module VirtualDesktop


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
        Start-Sleep -Milliseconds 5


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


$keyD1  = '0x7C' ## F13
$keyD2  = '0x7D' ## F14
$keyD3  = '0x7E' ## F15
$keyD4  = '0x7F' ## F16
$keyD5  = '0x80' ## F17
$keyD6  = '0x81' ## F18
$keyD7  = '0x82' ## F19
$keyD8  = '0x83' ## F20
$keyD9  = '0x84' ## F21

$keyWin = '0x5B' ## Win Key

#All these imports are copied from the internet, and I am not exactly sure what the syntax is, so I leave it as it is now
$SigAsyncKeyState= @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@

Add-Type -MemberDefinition $SigAsyncKeyState -Name Keyboard -Namespace PsOneApi -PassThru

$SigGetForegroundWindow= @'
    [DllImport("user32.dll")]
     public static extern IntPtr GetForegroundWindow();
'@
Add-Type $SigGetForegroundWindow -Name Utils -Namespace Win32

$SigShowWindowAsync = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
Add-Type -MemberDefinition $SigShowWindowAsync -name NativeMethods -namespace Win32


#not sure why this is done differently than the imports for the WaitFirefoxOpen function,
#but its from https://stackoverflow.com/questions/64469727/powershell-and-winapi-enumwindows-function
$SigEnumWindows= @'
// declare the EnumWindowsProc delegate type
public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

[DllImport("user32.dll")]
public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);
'@
Add-Type -MemberDefinition $SigEnumWindows -Name EnumWindowsUtil -Namespace Win32Functions

$SigSetForegroundWindow = @'
    [DllImport("user32.dll")] public static extern int SetForegroundWindow(IntPtr hwnd);
'@
Add-Type -MemberDefinition $SigSetForegroundWindow -Name EnumWindowsUtil -Namespace Win32Functions -PassThru

function SetFocusToTopmostWindow()
{
    "logging powershell" | Out-File -FilePath C:\Users\offen\output.txt 
    $targetHwnd = 0
    [Win32Functions.EnumWindowsUtil]::EnumWindows({
        #[void][Win32]::EnumThreadWindows($_.Id, {
            param($hwnd, $lparam)

            -join("checking hwnd: ", $hwnd, ", targethwnd:", $targetHwnd) | Out-File -FilePath C:\Users\offen\output.txt -append

            if ([Win32]::IsWindowVisible($hwnd)) {
                if ($targetHwnd -eq 0) {
                    $targetHwnd = $hwnd #I have no idea how to cancel the enumeration
                    "found hwnd" | Out-File -FilePath C:\Users\offen\output.txt -append
                }
            }}, 0)
            $targetHwnd | Out-File -FilePath C:\Users\offen\output.txt -append
    [Win32Functions.EnumWindowsUtil]::SetForegroundWindow($targetHwnd)
}


$LastKey7 = 0
$LastKey7AllowedTime = 1500
do
{  
	$result = [PsOneApi.Keyboard]::GetAsyncKeyState($keyD1)
	$result2 = [PsOneApi.Keyboard]::GetAsyncKeyState($keyD2)
	$result3 = [PsOneApi.Keyboard]::GetAsyncKeyState($keyD3)
	$result4 = [PsOneApi.Keyboard]::GetAsyncKeyState($keyD4)
	$result5 = [PsOneApi.Keyboard]::GetAsyncKeyState($keyD5)
	$result6 = [PsOneApi.Keyboard]::GetAsyncKeyState($keyD6)
	$result7 = [PsOneApi.Keyboard]::GetAsyncKeyState($keyD7)
	$result8 = [PsOneApi.Keyboard]::GetAsyncKeyState($keyD8)
	$result9 = [PsOneApi.Keyboard]::GetAsyncKeyState($keyD9)
	$resultWin = [PsOneApi.Keyboard]::GetAsyncKeyState($keyWin)

	$bWinPressed = [bool] (( $resultWin -eq -32767 ) -or ( $resultWin -eq -32768 ))

	If  (([bool] (( $result -eq -32767 ) -or ( $result -eq -32768 ))) -and $bWinPressed)
	{ 
		If($LastKey7 + $LastKey7AllowedTime -ge [Math]::Round((Get-Date).ToFileTimeUTC()/10000))
		{
			Get-Desktop 0 | Move-ActiveWindow
			$LastKey7 = 0	
		}
		Else {
			Get-Desktop  0 | Switch-Desktop
            Start-Sleep -Milliseconds 200
            SetFocusToTopmostWindow
		}
	}
	Elseif (([bool] (( $result2 -eq -32767 ) -or ( $result2 -eq -32768 ))) -and $bWinPressed)
	{
		If($LastKey7 + $LastKey7AllowedTime -ge [Math]::Round((Get-Date).ToFileTimeUTC()/10000))
		{
			Get-Desktop 1 | Move-ActiveWindow
			$LastKey7 = 0	
		}
		Else {
			Get-Desktop  1 | Switch-Desktop
            SetFocusToTopmostWindow
		}
	}
	Elseif (([bool] (( $result3 -eq -32767 ) -or ( $result3 -eq -32768 ))) -and $bWinPressed)
	{
		If($LastKey7 + $LastKey7AllowedTime -ge [Math]::Round((Get-Date).ToFileTimeUTC()/10000))
		{
			Get-Desktop 2 | Move-ActiveWindow
			$LastKey7 = 0	
		}
		Else {
			Get-Desktop  2 | Switch-Desktop
            SetFocusToTopmostWindow
		}
	}
	Elseif (([bool] (( $result4 -eq -32767 ) -or ( $result4 -eq -32768 ))) -and $bWinPressed)
	{
		If($LastKey7 + $LastKey7AllowedTime -ge [Math]::Round((Get-Date).ToFileTimeUTC()/10000))
		{
			Get-Desktop 3 | Move-ActiveWindow
			$LastKey7 = 0	
		}
		Else {
			Get-Desktop  3 | Switch-Desktop
            SetFocusToTopmostWindow
		}
	}
	Elseif (([bool] (( $result5 -eq -32767 ) -or ( $result5 -eq -32768 ))) -and $bWinPressed)
	{
		$hwnd = [Win32.Utils]::GetForegroundWindow()
		Pin-Window $hwnd
	}
	Elseif (([bool] (( $result6 -eq -32767 ) -or ( $result6 -eq -32768 ))) -and $bWinPressed)
	{
		$hwnd = [Win32.Utils]::GetForegroundWindow()
		Unpin-Window $hwnd
	}
	Elseif (([bool] (( $result7 -eq -32767 ) -or ( $result7 -eq -32768 ))) -and $bWinPressed)
	{
		$LastKey7 = [Math]::Round((Get-Date).ToFileTimeUTC()/10000)
	}
	Elseif (([bool] (( $result8 -eq -32767 ) -or ( $result8 -eq -32768 ))) -and $bWinPressed)
	{
		$Firefox= WaitFirefoxOpen -Arguments "-new-window -foreground" 
		[Window]::MoveWindow($Firefox, -8, 22, 1936, 1066, $True)
        [Win32.NativeMethods]::ShowWindowAsync($Firefox, 3)
	}
	Elseif (([bool] (( $result9 -eq -32767 ) -or ( $result9 -eq -32768 ))) -and $bWinPressed)
	{
		$Firefox= WaitFirefoxOpen -Arguments "-private-window" 
		[Window]::MoveWindow($Firefox, -8, 22, 1936, 1066, $True)
        [Win32.NativeMethods]::ShowWindowAsync($Firefox, 3)
	}
	
    Start-Sleep -Milliseconds 15

} while($true)

