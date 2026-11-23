# The window half of the one-click first run (Tools, 2026-11-23; path to Alpha 1, job 8). Windows PowerShell 5.1. Called by tools/first-run/first-run.mjs; prints ONE line of JSON.
#   window.ps1 -Action capture -ProcessId <pid> -Out <png> [-Crop x,y,w,h]    one still of the program's window (the part named by the fractions, if -Crop), plus how many distinct colours it has
#   window.ps1 -Action keys    -ProcessId <pid> -Keys ENTER,DOWN,P              presses the keys on the program's window, one after the other
# NEVER RUN AGAINST A GAME WINDOW BEFORE THE FIRST CLICK (no session opens a Godot window): the capture and the key presses are written from the Windows calls' documentation and checked only for syntax.
# It touches nothing but the window of the process it is given: the window is brought to the front, a still is taken of its client area from the screen, keys are sent as the keyboard would.
param(
  [Parameter(Mandatory = $true)][ValidateSet('capture', 'keys')][string]$Action,
  [Parameter(Mandatory = $true)][int]$ProcessId,
  [string]$Out = '',
  [string]$Crop = '',
  [string]$Keys = ''
)
$ErrorActionPreference = 'Stop'
function Say($o) { ($o | ConvertTo-Json -Compress) }
try {
  Add-Type -AssemblyName System.Drawing
  Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class FirstRunWin {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
}
'@
  [void][FirstRunWin]::SetProcessDPIAware()
  $p = Get-Process -Id $ProcessId -ErrorAction Stop
  $h = [IntPtr]::Zero
  for ($i = 0; $i -lt 40; $i++) { $p.Refresh(); $h = $p.MainWindowHandle; if ($h -ne [IntPtr]::Zero) { break }; Start-Sleep -Milliseconds 250 }
  if ($h -eq [IntPtr]::Zero) { Say @{ ok = $false; error = 'the program has no window yet' }; exit 0 }
  [void][FirstRunWin]::ShowWindow($h, 9)
  [void][FirstRunWin]::SetForegroundWindow($h)
  if ($Action -eq 'capture') {
    if (-not $Out) { Say @{ ok = $false; error = 'no -Out' }; exit 0 }
    $r = New-Object FirstRunWin+RECT
    [void][FirstRunWin]::GetClientRect($h, [ref]$r)
    $pt = New-Object FirstRunWin+POINT
    [void][FirstRunWin]::ClientToScreen($h, [ref]$pt)
    $w = $r.Right - $r.Left; $hh = $r.Bottom - $r.Top
    if ($w -lt 16 -or $hh -lt 16) { Say @{ ok = $false; error = "the window is $w by $hh" }; exit 0 }
    Start-Sleep -Milliseconds 120
    $bmp = New-Object System.Drawing.Bitmap $w, $hh
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($pt.X, $pt.Y, 0, 0, (New-Object System.Drawing.Size $w, $hh))
    $g.Dispose()
    # distinct colours and a signature of a 32 by 18 sample (quantised so a one-pixel flicker does not change it)
    $seen = @{}; $sig = New-Object System.Text.StringBuilder
    for ($y = 0; $y -lt 18; $y++) { for ($x = 0; $x -lt 32; $x++) {
      $c = $bmp.GetPixel([int](($x + 0.5) * $w / 32), [int](($y + 0.5) * $hh / 18))
      $q = ([int]($c.R / 32)) * 64 + ([int]($c.G / 32)) * 8 + ([int]($c.B / 32))
      $seen[$q] = 1; [void]$sig.Append($q.ToString('x') + ',')
    } }
    $save = $bmp
    if ($Crop) {
      $f = $Crop.Split(',') | ForEach-Object { [double]$_ }
      $rect = New-Object System.Drawing.Rectangle ([int]($f[0] * $w)), ([int]($f[1] * $hh)), ([int]($f[2] * $w)), ([int]($f[3] * $hh))
      $save = $bmp.Clone($rect, $bmp.PixelFormat)
    }
    $save.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
    $md5 = [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::ASCII.GetBytes($sig.ToString()))).Replace('-', '').ToLower()
    Say @{ ok = $true; w = $w; h = $hh; colours = $seen.Count; signature = $md5; file = (Split-Path -Leaf $Out) }
  } else {
    $vk = @{ ENTER = 0x0D; ESC = 0x1B; SPACE = 0x20; UP = 0x26; DOWN = 0x28; LEFT = 0x25; RIGHT = 0x27; P = 0x50; F1 = 0x70; TAB = 0x09 }
    $n = 0
    foreach ($k in ($Keys.Split(',') | Where-Object { $_ })) {
      if (-not $vk.ContainsKey($k)) { Say @{ ok = $false; error = "unknown key $k" }; exit 0 }
      [FirstRunWin]::keybd_event([byte]$vk[$k], 0, 0, [UIntPtr]::Zero)
      Start-Sleep -Milliseconds 90
      [FirstRunWin]::keybd_event([byte]$vk[$k], 0, 2, [UIntPtr]::Zero)
      Start-Sleep -Milliseconds 260
      $n++
    }
    Say @{ ok = $true; pressed = $n }
  }
} catch {
  Say @{ ok = $false; error = ($_.Exception.Message -replace '[\r\n]+', ' ') }
}
