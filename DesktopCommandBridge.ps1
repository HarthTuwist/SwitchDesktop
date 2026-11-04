# The main PowerShell thread reads commands from its window's Windows message
# queue. Only the latest pending command is executed after a busy action.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -ReferencedAssemblies System.dll, System.Core.dll, System.Windows.Forms.dll -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public sealed class DesktopCommandBridge : NativeWindow, IDisposable
{
    public const int CommandMessage = 0x8029; // AutoHotkey -> PowerShell: command number in wParam.
    public const int FocusMessage = 0x802A;   // PowerShell -> AutoHotkey: restore focus after a desktop switch.

    // Layout of the Win32 MSG structure, used by PeekMessage.
    [StructLayout(LayoutKind.Sequential)]
    private struct NativeMessage
    {
        public IntPtr Window;
        public uint Message;
        public UIntPtr WParam;
        public IntPtr LParam;
        public uint Time;
        public int X, Y;
        public uint Private;
    }

    [DllImport("user32.dll")]
    private static extern bool PeekMessage(out NativeMessage message, IntPtr hwnd,
        uint minMessage, uint maxMessage, uint removeMessage);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool PostMessage(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool IsWindow(IntPtr hwnd);

    public DesktopCommandBridge()
    {
        CreateHandle(new CreateParams { Caption = "SwitchDesktopCommandWindow" });
    }

    public int NextCommand()
    {
        NativeMessage message;
        // Drain pending messages and keep the latest valid command. Shutdown
        // takes precedence so startup cleanup cannot accidentally be cancelled.
        int latest = 0;
        while (PeekMessage(out message, Handle, CommandMessage, CommandMessage, 1))
        {
            ulong command = message.WParam.ToUInt64();
            if (command == 10) return 10;
            if (command >= 1 && command <= 11) latest = (int)command;
        }
        return latest;
    }

    // Only needed when the PowerShell session outlives the bridge, e.g. in tests.
    // The backend never calls it: Windows destroys the window when the process exits.
    public void Dispose()
    {
        DestroyHandle();
    }
}
'@
