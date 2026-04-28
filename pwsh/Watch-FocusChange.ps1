# 监控窗口焦点切换 - 基于 SetWinEventHook 回调，可捕获瞬间焦点窃取
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class FocusHook {
public delegate void WinEventDelegate(IntPtr hWinEventHook, uint eventType, IntPtr hwnd, int idObject, int idChild, uint dwEventThread, uint dwmsEventTime);

[DllImport("user32.dll")]
public static extern IntPtr SetWinEventHook(uint eventMin, uint eventMax, IntPtr hmodWinEventProc, WinEventDelegate lpfnWinEventProc, uint idProcess, uint idThread, uint dwFlags);

[DllImport("user32.dll")]
public static extern bool UnhookWinEvent(IntPtr hWinEventHook);

[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

[DllImport("user32.dll")]
public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out int lpdwProcessId);

public const uint EVENT_SYSTEM_FOREGROUND = 0x0003;
public const uint WINEVENT_OUTOFCONTEXT = 0x0000;
}
"@

$callback = [FocusHook+WinEventDelegate]{
param($hHook, $eventType, $hwnd, $idObject, $idChild, $thread, $timeStamp)
$curPid = 0
[FocusHook]::GetWindowThreadProcessId($hwnd, [ref]$curPid) | Out-Null
if ($curPid -eq 0) { return }

$sb = [System.Text.StringBuilder]::new(256)
[FocusHook]::GetWindowText($hwnd, $sb, 256) | Out-Null
$title = $sb.ToString()

$proc = Get-Process -Id $curPid -ErrorAction SilentlyContinue
if (-not $proc) { return }

try { $path = $proc.MainModule.FileName } catch { $path = "(无法访问)" }

$now = Get-Date -Format "HH:mm:ss.fff"
Write-Host "[$now] $($proc.Name) (PID: $curPid) 窗口: $title`n  路径: $path" -ForegroundColor Yellow
}

# 防止委托被 GC 回收导致钩子失效
$handle = [System.Runtime.InteropServices.GCHandle]::Alloc($callback)
$hookPtr = [FocusHook]::SetWinEventHook(
[FocusHook]::EVENT_SYSTEM_FOREGROUND,
[FocusHook]::EVENT_SYSTEM_FOREGROUND,
[IntPtr]::Zero,
$callback,
0, 0,
[FocusHook]::WINEVENT_OUTOFCONTEXT
)

if ($hookPtr -eq [IntPtr]::Zero) {
Write-Host "SetWinEventHook 失败，可能需要管理员权限" -ForegroundColor Red
$handle.Free()
return
}

Write-Host "焦点钩子已安装，按 Ctrl+C 退出..." -ForegroundColor Cyan
Write-Host ("-" * 60)

try {
# 消息循环：钩子回调依赖窗口消息派发
while ($true) {
[System.Windows.Forms.Application]::DoEvents()
Start-Sleep -Milliseconds 50
}
} finally {
[FocusHook]::UnhookWinEvent($hookPtr) | Out-Null
$handle.Free()
Write-Host "`n钩子已卸载" -ForegroundColor Cyan
}
