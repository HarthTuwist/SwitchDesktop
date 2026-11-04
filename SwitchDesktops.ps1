param([long]$WrapperWindow = 0)

$host.ui.RawUI.WindowTitle = "SwitchDesktopsPowershell"
Import-Module VirtualDesktop
# Reuse VirtualDesktop's COM definitions, bypassing MakeVisible's taskbar handling.
function Switch-DesktopDirect {
    param([Parameter(Mandatory)][int]$Index)

    $desktop = [VirtualDesktop.Desktop]::FromIndex($Index)
    $flags = [Reflection.BindingFlags]'Instance,NonPublic'
    $nativeDesktop = [VirtualDesktop.Desktop].GetField('ivd', $flags).GetValue($desktop)
    $assembly = [VirtualDesktop.Desktop].Assembly
    $managerType = $assembly.GetType('VirtualDesktop.DesktopManager', $true)
    $manager = $managerType.GetField('VirtualDesktopManagerInternal',
        [Reflection.BindingFlags]'Static,NonPublic').GetValue($null)
    $method = $assembly.GetType('VirtualDesktop.IVirtualDesktopManagerInternal', $true).GetMethod('SwitchDesktop')
    $arguments = if ($method.GetParameters().Count -eq 2) {
        [object[]]@([IntPtr]::Zero, $nativeDesktop)
    } else {
        [object[]]@($nativeDesktop)
    }
    [void]$method.Invoke($manager, $arguments)
}

$LionSpecial = $false
#$LionSpecial = $true

$LaptopFirefoxTarget = [PSCustomObject]@{
	XPos = -13
	YPos = -13
	Width = 3266
	Height = 2106
}

$FirefoxTarget = [PSCustomObject]@{
	XPos = -8
	YPos = 22
	Width = 1936
	Height = 1066
}

#comment this in to use the Laptop window target for creating new browser windows instead of the desktop one
$FirefoxTarget = $LaptopFirefoxTarget

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
    [Win32Functions.EnumWindowsUtil]::EnumWindows({
        #[void][Win32]::EnumThreadWindows($_.Id, {
            param($hwnd, $lparam)

            -join("checking hwnd: ", $hwnd ) | Out-File -FilePath C:\Users\offen\output.txt -append

            if ([Win32]::IsWindowVisible($hwnd)) {
                    "found hwnd" | Out-File -FilePath C:\Users\offen\output.txt -append
                    [Win32Functions.EnumWindowsUtil]::SetForegroundWindow($hwnd)
                    return $false
                }
                return $true
            }, 0)
}

$RefreshSpotifyTokenScriptBlock = 
{
        #Read the refresh token (which seems to have unlimited validity) from the result from the Original Access call
        $refreshtoken = (Get-Content -Path C:\SwitchDesktopScripts\Secrets\OriginalAccessToken.json | ConvertFrom-Json).refresh_token

        #Read the Client_id:Client_secret, converted to base 64 and prefaced with "Base" from this file (cumbersome to reencode it every time)
		$idsecretb64 = (Get-Content -Path C:\SwitchDesktopScripts\Secrets\Base64IdSecret.json | ConvertFrom-Json).idsecretb64
		
        #make the actual call
		$refreshBody = @{
            grant_type="refresh_token"
            refresh_token=$refreshtoken}
		$refreshHeader = @{'Authorization' = $idsecretb64}
		$refreshobj = Invoke-WebRequest -UseBasicParsing -Method "POST" -Headers $refreshHeader -Body $refreshBody -Uri 'https://accounts.spotify.com/api/token' ; $refreshobj.Content | Out-File -FilePath C:\SwitchDesktopScripts\Secrets\AccessToken.json
		

}

#Refresh the access token on startup
#Invoke-Command here instead of Start-Job such that we wait on the result
Invoke-Command -ScriptBlock $RefreshSpotifyTokenScriptBlock

$script:SpotifyIDOfDevice = 0
#Via the API, get the ID of the current device
function SetSpotifyIDOfDevice{
    $GetIDAaccesstoken = (Get-Content -Path C:\SwitchDesktopScripts\Secrets\AccessToken.json | ConvertFrom-Json).access_token
    $GetIDHeader = @{'Authorization' = (-join("Bearer ", $GetIDAaccesstoken))}
    $GetIDResult = Invoke-WebRequest -UseBasicParsing -Method "GET" -Headers $GetIDHeader -Uri 'https://api.spotify.com/v1/me/player/devices'

    $script:SpotifyIDOfDevice=(($GetIDResult.Content | ConvertFrom-Json).devices | Where {$_.name -eq (Hostname)}).id
}


$LastKey7 = 0#Do not pretend Key7 was pressed when starting up, thatd be weird
$LastKey7AllowedTime = 1500 

$TimeBetweenTokenRefreshes = 300000 #300 seconds = 6m
#$LastTokenrefreshTime = [decimal]::MaxValue #Start with a refresh when starting the script,  
#$LastTokenrefreshTime = [bigint]::Pow(10,20) #Do not use MaxValue, as we cannot add on it. This should be further away than the death of the sun
$LastTokenrefreshTime = 0

$script:LastHwndDesk0 = 0
$script:LastHwndDesk1 = 0
$script:LastHwndDesk2 = 0
$script:LastHwndDesk3 = 0
function StoreDesktopLastWindow
{
        "StoreDesktopLastWindow" | Out-File -FilePath C:\Users\offen\output.txt -append
        $CurDeskNumber = (Get-DesktopList | Where {$_.Visible -eq $true}).Number
    if ($CurDeskNumber -eq 0) {
        $script:LastHwndDesk0 =  [Win32.Utils]::GetForegroundWindow()
         $script:LastHwndDesk0 | Out-File -FilePath C:\Users\offen\output.txt -append
    }
}




#############################################Actual permanent while loop starts here
#############################################Actual permanent while loop starts here
#############################################Actual permanent while loop starts here
#############################################Actual permanent while loop starts here




. "$PSScriptRoot\DesktopCommandBridge.ps1"
$commandBridge = New-Object DesktopCommandBridge
do
{
#####################################Receive the next command

	$command = $commandBridge.NextCommand()

	If ($command -eq 1)
	{ 
		If($LastKey7 + $LastKey7AllowedTime -ge [Math]::Round((Get-Date).ToFileTimeUTC()/10000))
		{
			Get-Desktop 0 | Move-ActiveWindow
			$LastKey7 = 0	
		}
		Else {
			Switch-DesktopDirect 0
        #    Start-Sleep -Milliseconds 100
            #SetFocusToTopmostWindow
             #-join ("switching to", $script:LastHwndDesk0) | Out-File -FilePath C:\Users\offen\output.txt -append

#         $OriginalWindows = New-Object System.Collections.ArrayList
#		Get-Process | %{
#		$proc = -join ($_.id, $_.ProcessName)
#         $_.Threads.ForEach({
#             [void][Win32]::EnumThreadWindows($_.Id, {
#                 param($hwnd, $lparam)
#                 if (($hwnd -eq $script:LastHwndDesk0)) {
#                  #   $OriginalWindows.Add($hwnd)
#					 #$OriginalWindows.Add($proc)
#                     -join($script:LastHwndDesk0 , ",", $proc) | Out-File -FilePath C:\Users\offen\output.txt -append
#                 }}, 0)
#             })}
             
            #$OriginalWindows | Out-File -FilePath C:\Users\offen\output.txt 
             #Get-Process | Where-Object { $_.mainWindowHandle -eq $script:LastHwndDesk0 } | Select-Object processName, MainWindowTItle, MainWindowHandle, Id |  Out-File -FilePath C:\Users\offen\output.txt -append

            Start-Sleep -Milliseconds 100
             [void][DesktopCommandBridge]::PostMessage([IntPtr]$WrapperWindow, [DesktopCommandBridge]::FocusMessage, [IntPtr]$PID, [IntPtr]::Zero)
            #[Win32Functions.EnumWindowsUtil]::SetForegroundWindow($script:LastHwndDesk0)
    #        [Win32.NativeMethods]::ShowWindowAsync($script:LastHwndDesk0, 1) #1 = do not change whether minimized or maximized
		}
	}
	Elseif ($command -eq 2)
	{
		If($LastKey7 + $LastKey7AllowedTime -ge [Math]::Round((Get-Date).ToFileTimeUTC()/10000))
		{
			Get-Desktop 1 | Move-ActiveWindow
			$LastKey7 = 0	
		}
		Else {
            #StoreDesktopLastWindow
			Switch-DesktopDirect 1
            Start-Sleep -Milliseconds 100
             [void][DesktopCommandBridge]::PostMessage([IntPtr]$WrapperWindow, [DesktopCommandBridge]::FocusMessage, [IntPtr]$PID, [IntPtr]::Zero)
         #   Start-Sleep -Milliseconds 200
         #   SetFocusToTopmostWindow
		}
	}
	Elseif ($command -eq 3)
	{
		If($LastKey7 + $LastKey7AllowedTime -ge [Math]::Round((Get-Date).ToFileTimeUTC()/10000))
		{
			Get-Desktop 2 | Move-ActiveWindow
			$LastKey7 = 0	
		}
		Else {
			Switch-DesktopDirect 2
            Start-Sleep -Milliseconds 100
             [void][DesktopCommandBridge]::PostMessage([IntPtr]$WrapperWindow, [DesktopCommandBridge]::FocusMessage, [IntPtr]$PID, [IntPtr]::Zero)
            #SetFocusToTopmostWindow
		}
	}
	Elseif ($command -eq 4)
	{
		If($LastKey7 + $LastKey7AllowedTime -ge [Math]::Round((Get-Date).ToFileTimeUTC()/10000))
		{
			Get-Desktop 3 | Move-ActiveWindow
			$LastKey7 = 0	
		}
		Else {
			Switch-DesktopDirect 3
            Start-Sleep -Milliseconds 100
             [void][DesktopCommandBridge]::PostMessage([IntPtr]$WrapperWindow, [DesktopCommandBridge]::FocusMessage, [IntPtr]$PID, [IntPtr]::Zero)
            #SetFocusToTopmostWindow
		}
	}
	Elseif ($command -eq 5)
	{
		$hwnd = [Win32.Utils]::GetForegroundWindow()
		Pin-Window $hwnd
	}
	Elseif ($command -eq 6)
	{
		$hwnd = [Win32.Utils]::GetForegroundWindow()
		Unpin-Window $hwnd
	}
	Elseif ($command -eq 7)
	{
		$LastKey7 = [Math]::Round((Get-Date).ToFileTimeUTC()/10000)
	}
	Elseif ($command -eq 8)
	{
        if (-Not $LionSpecial) 
        {
	        $Firefox= WaitFirefoxOpen -Arguments "-new-window -foreground" 
	            [Window]::MoveWindow($Firefox, $FirefoxTarget.XPos, $FirefoxTarget.YPos, $FirefoxTarget.Width, $FirefoxTarget.Height, $True)
	            [Win32.NativeMethods]::ShowWindowAsync($Firefox, 3)
        }
        else {
            $accesstoken = (Get-Content -Path C:\SwitchDesktopScripts\Secrets\AccessToken.json | ConvertFrom-Json).access_token

            $SongIdHeader = @{'Authorization' = (-join("Bearer ", $accesstoken))}
            $SongIdResult = Invoke-WebRequest -UseBasicParsing -Method "GET" -Headers $SongIdHeader -Uri 'https://api.spotify.com/v1/me/player/currently-playing'


            if($SongIdResult.StatusCode -eq 200)
            {
                $CurrentSongId = ($SongIdResult.Content | ConvertFrom-Json).item.id

                $LikeSongHeader = @{'Authorization' = (-join("Bearer ", $accesstoken))
                    'Accept' = 'application/json'
                    'Content-Type' = 'application/json'}
                $LikeSongResult = Invoke-WebRequest -UseBasicParsing -Method "PUT" -Headers $LikeSongHeader -Uri (-join('https://api.spotify.com/v1/me/tracks?ids=', $CurrentSongId))
            }
        }
    }
	Elseif ($command -eq 9)
	{
		$Firefox= WaitFirefoxOpen -Arguments "-private-window" 
		[Window]::MoveWindow($Firefox, $FirefoxTarget.XPos, $FirefoxTarget.YPos, $FirefoxTarget.Width, $FirefoxTarget.Height, $True)
        [Win32.NativeMethods]::ShowWindowAsync($Firefox, 3)
	}
	Elseif ($command -eq 10)
	{
        exit
	}
    
	Elseif ($command -eq 11)
	{
        #if we do not have a device ID, mainly because spotify started after the script, set the device id here
        #TODO: Can the device ID change while running, or with restarting spotify? I do not think it does
        if(-Not $script:SpotifyIDOfDevice)
        {
            SetSpotifyIDOfDevice
        }
        #Only do the query if we actually found a device above
        if($script:SpotifyIDOfDevice)
        {     
            $accesstoken = (Get-Content -Path C:\SwitchDesktopScripts\Secrets\AccessToken.json | ConvertFrom-Json).access_token

            $ButtonPressHeader = @{'Authorization' = (-join("Bearer ", $accesstoken))}
            $ButtonPressResult = Invoke-WebRequest -UseBasicParsing -Method "POST" -Headers $ButtonPressHeader -Uri (-join('https://api.spotify.com/v1/me/player/next?device_id=', $SpotifyIDOfDevice))
            #$ButtonPressResult  | Out-File -FilePath C:\Users\offen\output.txt  -append
       }
	}


##################################### Handle the check whether we need to refresh the Spotify Access Token
#this is not done in its own background job to clarify problems 

    #-join("tokenrefresh", $LastTokenrefreshTime, ",") | Out-File -FilePath C:\Users\offen\output.txt  -append
    If($LastTokenrefreshTime + $TimeBetweenTokenRefreshes -le [Math]::Round((Get-Date).ToFileTimeUTC()/10000) )
    {
        #-join("tokenrefresh", $LastTokenrefreshTime, ",", [Math]::Round((Get-Date).ToFileTimeUTC()/10000) + $TimeBetweenTokenRefreshes) | Out-File -FilePath C:\Users\offen\output.txt  -append
        Start-Job -ScriptBlock $RefreshSpotifyTokenScriptBlock
		$LastTokenrefreshTime = [Math]::Round((Get-Date).ToFileTimeUTC()/10000)
    }



#####################################Skip some time before returning to the top, so we don't take to much proccessor time
    Start-Sleep -Milliseconds 15

} while($true)

