param([string]$AutoHotkeyPath = 'C:\Program Files\AutoHotkey\AutoHotkey.exe')

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
foreach ($file in @('SwitchDesktops.ps1', 'DesktopCommandBridge.ps1')) {
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $repoRoot $file), [ref]$null, [ref]$parseErrors)
    if ($parseErrors) { throw ($parseErrors | Out-String) }
}
. "$repoRoot\DesktopCommandBridge.ps1"
$previousBridge = New-Object DesktopCommandBridge
$bridge = New-Object DesktopCommandBridge
$bridgeHandle = $bridge.Handle
$testDir = Join-Path ([IO.Path]::GetTempPath()) ('DesktopBridgeTest-' + [Guid]::NewGuid())
[void](New-Item -ItemType Directory -Path $testDir)
$marker = Join-Path $testDir 'focus.txt'
$ready = Join-Path $testDir 'ready.txt'
$sent = Join-Path $testDir 'sent.txt'
$harnessPath = Join-Path $testDir 'BridgeTest.ahk'
$wrapper = Get-Content "$repoRoot\SwitchDesktopWrapper.ahk" -Raw
$start = $wrapper.IndexOf('SendDesktopCommand(command,')
$end = $wrapper.IndexOf('FocusDesktopWindow(', $start)
$functions = $wrapper.Substring($start, $end - $start)
$startupFunctionStart = $wrapper.IndexOf('StopDesktopBackend(', $end)
$startupFunctionEnd = $wrapper.IndexOf('<#c::', $startupFunctionStart)
$startupFunction = $wrapper.Substring($startupFunctionStart, $startupFunctionEnd - $startupFunctionStart)
$harness = @'
#NoTrayIcon
#SingleInstance Off
DesktopBackendPID := BACKEND_PID
;Record the callback without activating any of the user's windows.
OnMessage(0x802A, "RecordFocusMessage")
DllCall("ChangeWindowMessageFilterEx", "Ptr", A_ScriptHwnd, "UInt", 0x802A, "UInt", 1, "Ptr", 0)
StopDesktopBackend("ahk_id PREVIOUS_HANDLE")
FileAppend, %A_ScriptHwnd%, READY_PATH
    Loop, 9
    SendDesktopCommand(A_Index, false)
SendDesktopCommand(11, false)
FileAppend, sent, SENT_PATH
SetTimer, Timeout, -10000
return

Timeout:
    ExitApp, 1
return

RecordFocusMessage(senderPID, lParam, msg, hwnd)
{
    global DesktopBackendPID
    if (senderPID != DesktopBackendPID)
        return
    FileAppend, focus received, MARKER_PATH
    ExitApp
}

'@
$harness = $harness.Replace('BACKEND_PID', [string]$PID).Replace('READY_PATH', $ready).Replace('MARKER_PATH', $marker).Replace('SENT_PATH', $sent).Replace('PREVIOUS_HANDLE', [string]$previousBridge.Handle)
[IO.File]::WriteAllText($harnessPath, $harness + $functions + $startupFunction)
try {
    # Invalid messages must not become actions.
    foreach ($command in @(0, 12)) {
        if (-not [DesktopCommandBridge]::PostMessage($bridge.Handle,
            [DesktopCommandBridge]::CommandMessage, [IntPtr]$command, [IntPtr]::Zero)) {
            throw 'PostMessage failed.'
        }
    }
    $process = Start-Process -FilePath $AutoHotkeyPath -ArgumentList @('/ErrorStdOut', "`"$harnessPath`"") -WindowStyle Hidden -PassThru
    # Restrict startup cleanup to our isolated previous receiver, never a live backend.
    $deadline = (Get-Date).AddSeconds(4)
    $shutdownCommand = 0
    while ($shutdownCommand -eq 0 -and (Get-Date) -lt $deadline) {
        $shutdownCommand = $previousBridge.NextCommand()
        if ($shutdownCommand -eq 0) { Start-Sleep -Milliseconds 10 }
    }
    if ($shutdownCommand -ne 10) { throw 'Startup did not request shutdown of the previous receiver.' }
    if (Test-Path $sent) { throw 'Commands were sent before the previous receiver closed.' }
    $previousBridge.Dispose()
    $previousBridge = $null
    # Simulate a busy action: let AutoHotkey finish sending before reading any
    # commands, then verify only the latest command is returned.
    $deadline = (Get-Date).AddSeconds(5)
    while (-not (Test-Path $sent) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 10
    }
    if (-not (Test-Path $sent)) { throw 'AutoHotkey did not finish sending commands.' }
    Write-Output 'PASS: startup sends shutdown and waits for the previous receiver to close.'
    Start-Sleep -Milliseconds 100
    $received = $bridge.NextCommand()
    if ($received -ne 11) { throw "Expected latest command 11, got $received." }
    if ($bridge.NextCommand() -ne 0) { throw 'Invalid command accepted.' }
    Write-Output 'PASS: only the latest pending command is returned; invalid commands rejected.'

    $wrapperHandle = [IntPtr][long](Get-Content $ready -Raw)
    if (-not [DesktopCommandBridge]::PostMessage($wrapperHandle,
        [DesktopCommandBridge]::FocusMessage, [IntPtr]$PID, [IntPtr]::Zero)) {
        throw 'Focus callback failed.'
    }
    $deadline = (Get-Date).AddSeconds(3)
    while (-not (Test-Path $marker) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 10
    }
    if (-not (Test-Path $marker)) { throw 'AutoHotkey did not receive the focus callback.' }
    Write-Output 'PASS: PowerShell focus callback reaches the AutoHotkey handler.'
    if (-not $process.WaitForExit(2000)) { throw 'AutoHotkey did not exit.' }
    if ($bridge.NextCommand() -ne 0) { throw 'Exiting unexpectedly sent a backend command.' }
    Write-Output 'PASS: AutoHotkey exits without sending a shutdown command.'
} finally {
    if ($previousBridge) { $previousBridge.Dispose() }
    $bridge.Dispose()
    if ($process) { [void]$process.WaitForExit(11000) }
    # Only remove the individually named test artifacts inside this test directory.
    foreach ($path in @($marker, $ready, $sent, $harnessPath)) {
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path }
    }
    Remove-Item -LiteralPath $testDir
}
if ([DesktopCommandBridge]::IsWindow($bridgeHandle)) { throw 'Command window was not closed.' }
Write-Output 'PASS: hidden command window is cleaned up; PowerShell syntax is valid.'
