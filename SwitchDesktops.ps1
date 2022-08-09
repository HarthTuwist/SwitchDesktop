$host.ui.RawUI.WindowTitle = "SwitchDesktopsPowershell"
Import-Module VirtualDesktop


$keyD1  = '0x7C' ## F13
$keyD2  = '0x7D' ## F14
$keyD3  = '0x7E' ## F15
$keyD4  = '0x7F' ## F16
$keyD5  = '0x80' ## F17
$keyD6  = '0x81' ## F18
$keyD7  = '0x82' ## F19

$keyWin = '0x5B' ## Win Key

$Signature = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@

Add-Type -MemberDefinition $Signature -Name Keyboard -Namespace PsOneApi -PassThru

$code = @'
    [DllImport("user32.dll")]
     public static extern IntPtr GetForegroundWindow();
'@
Add-Type $code -Name Utils -Namespace Win32

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
		}
	}
	Elseif (([bool] (( $result2 -eq -32767 ) -or ( $result2 -eq -32768 ))) -and $bWinPressed)
	{
		If($LastKey7 + $LastKey7AllowedTime -ge [Math]::Round((Get-Date).ToFileTimeUTC()/10000))
		{
			Get-Desktop 1 | Move-ActiveWindow
			$LastKey7 = 1	
		}
		Else {
			Get-Desktop  1 | Switch-Desktop
		}
	}
	Elseif (([bool] (( $result3 -eq -32767 ) -or ( $result3 -eq -32768 ))) -and $bWinPressed)
	{
		If($LastKey7 + $LastKey7AllowedTime -ge [Math]::Round((Get-Date).ToFileTimeUTC()/10000))
		{
			Get-Desktop 2 | Move-ActiveWindow
			$LastKey7 = 2	
		}
		Else {
			Get-Desktop  2 | Switch-Desktop
		}
	}
	Elseif (([bool] (( $result4 -eq -32767 ) -or ( $result4 -eq -32768 ))) -and $bWinPressed)
	{
		If($LastKey7 + $LastKey7AllowedTime -ge [Math]::Round((Get-Date).ToFileTimeUTC()/10000))
		{
			Get-Desktop 3 | Move-ActiveWindow
			$LastKey7 = 3	
		}
		Else {
			Get-Desktop  3 | Switch-Desktop
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

		#Get-Desktop 0 | Move-ActiveWindow
	}

    Start-Sleep -Milliseconds 15

} while($true)

