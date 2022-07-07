$host.ui.RawUI.WindowTitle = "SwitchDesktopsPowershell"

$keyD1  = '0x7C' ## F13
$keyD2  = '0x7D' ## F14
$keyD3  = '0x7E' ## F15
$keyD4  = '0x7F' ## F16

$keyWin = '0x5B' ## Win Key

$Signature = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@
Add-Type -MemberDefinition $Signature -Name Keyboard -Namespace PsOneApi -PassThru
do
{  
	$result = [PsOneApi.Keyboard]::GetAsyncKeyState($keyD1)
	$result2 = [PsOneApi.Keyboard]::GetAsyncKeyState($keyD2)
	$result3 = [PsOneApi.Keyboard]::GetAsyncKeyState($keyD3)
	$result4 = [PsOneApi.Keyboard]::GetAsyncKeyState($keyD4)
	$resultWin = [PsOneApi.Keyboard]::GetAsyncKeyState($keyWin)

	$bWinPressed = [bool] (( $resultWin -eq -32767 ) -or ( $resultWin -eq -32768 ))

	If  (([bool] (( $result -eq -32767 ) -or ( $result -eq -32768 ))) -and $bWinPressed)
	{ 
		Get-Desktop  0 | Switch-Desktop
	}
	Elseif (([bool] (( $result2 -eq -32767 ) -or ( $result2 -eq -32768 ))) -and $bWinPressed)
	{
		Get-Desktop  1 | Switch-Desktop
	}
	Elseif (([bool] (( $result3 -eq -32767 ) -or ( $result3 -eq -32768 ))) -and $bWinPressed)
	{
		Get-Desktop  2 | Switch-Desktop
	}
		Elseif (([bool] (( $result4 -eq -32767 ) -or ( $result4 -eq -32768 ))) -and $bWinPressed)
	{
		Get-Desktop  3 | Switch-Desktop
	}

    Start-Sleep -Milliseconds 15

} while($true)

