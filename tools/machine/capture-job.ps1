# Starts a capture browser inside a Windows Job Object and keeps it there (tools/machine/browser.mjs starts this, nobody else should):
#   - the job is KILL_ON_JOB_CLOSE: when this script ends for ANY reason (it is killed, the machine logs it off) the whole browser tree dies with it;
#   - the job runs on at most -CpuPercent of the machine's logical processors (an affinity mask on the highest-numbered ones: 25 is 4 of 16 cores; the software renderer, SwiftShader, is otherwise free to take every core);
#   - the browser tree runs at below-normal priority;
#   - this script is the watchdog: it polls the launching node process (-ParentPid) and the deadline (-DeadlineMs, Unix milliseconds) and ends the job when the parent is gone, the
#     deadline passes, or the browser tree has exited. It writes why into the registry file (-Registry) before it does.
# No install: Windows PowerShell 5.1 and the .NET Framework that ship with Windows (Add-Type compiles the few P/Invoke lines below).
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [Parameter(Mandatory = $true)][string]$ArgsFile,
  [Parameter(Mandatory = $true)][int]$ParentPid,
  [Parameter(Mandatory = $true)][long]$DeadlineMs,
  [int]$CpuPercent = 25,
  [ValidateSet('BelowNormal', 'Normal')][string]$Priority = 'BelowNormal',
  [int]$IdleSeconds = 0,
  [string]$Registry = ''
)
$ErrorActionPreference = 'Stop'
$src = @'
using System;
using System.Runtime.InteropServices;
public static class CapJob {
  [StructLayout(LayoutKind.Sequential)] struct BASIC { public long PerProcessUserTimeLimit; public long PerJobUserTimeLimit; public uint LimitFlags; public UIntPtr MinimumWorkingSetSize; public UIntPtr MaximumWorkingSetSize; public uint ActiveProcessLimit; public UIntPtr Affinity; public uint PriorityClass; public uint SchedulingClass; }
  [StructLayout(LayoutKind.Sequential)] struct IOC { public ulong a, b, c, d, e, f; }
  [StructLayout(LayoutKind.Sequential)] struct EXT { public BASIC Basic; public IOC Io; public UIntPtr ProcessMemoryLimit; public UIntPtr JobMemoryLimit; public UIntPtr PeakProcessMemoryUsed; public UIntPtr PeakJobMemoryUsed; }
  [StructLayout(LayoutKind.Sequential)] struct CPU { public uint ControlFlags; public uint CpuRate; }
  [StructLayout(LayoutKind.Sequential)] struct ACCT { public long TotalUserTime; public long TotalKernelTime; public long ThisPeriodTotalUserTime; public long ThisPeriodTotalKernelTime; public uint TotalPageFaultCount; public uint TotalProcesses; public uint ActiveProcesses; public uint TotalTerminatedProcesses; }
  [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] static extern IntPtr CreateJobObject(IntPtr attrs, string name);
  [DllImport("kernel32.dll")] static extern bool SetInformationJobObject(IntPtr job, int cls, IntPtr info, int len);
  [DllImport("kernel32.dll")] static extern bool QueryInformationJobObject(IntPtr job, int cls, IntPtr info, int len, IntPtr ret);
  [DllImport("kernel32.dll")] static extern bool AssignProcessToJobObject(IntPtr job, IntPtr proc);
  [DllImport("kernel32.dll")] static extern bool TerminateJobObject(IntPtr job, uint code);
  [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
  static IntPtr job = IntPtr.Zero;
  static void Set(int cls, object s) {
    int n = Marshal.SizeOf(s.GetType());
    IntPtr p = Marshal.AllocHGlobal(n);
    try { Marshal.StructureToPtr(s, p, false); if (!SetInformationJobObject(job, cls, p, n)) throw new Exception("SetInformationJobObject " + cls + " failed: " + Marshal.GetLastWin32Error()); }
    finally { Marshal.FreeHGlobal(p); }
  }
  // creates the job (kill on close, below-normal priority, a hard CPU cap) and puts THIS process in it, so everything this process starts is in it too
  public static void Create(int cpuPercent, bool belowNormal) {
    job = CreateJobObject(IntPtr.Zero, null);
    if (job == IntPtr.Zero) throw new Exception("CreateJobObject failed: " + Marshal.GetLastWin32Error());
    EXT e = new EXT();
    e.Basic.LimitFlags = 0x2000 | (belowNormal ? 0x20u : 0u);   // KILL_ON_JOB_CLOSE | PRIORITY_CLASS
    e.Basic.PriorityClass = 0x4000;                              // BELOW_NORMAL_PRIORITY_CLASS
    // the CPU cap is an affinity mask: the highest-numbered logical processors, cpuPercent of them (at least one). A hard CPU RATE cap was tried first and starved the browser's start-up
    // on a busy machine (its threads are frozen for the rest of each interval and the start-up's handshakes crawl); a mask lets the threads run at full speed on fewer cores, and
    // every capture started this way shares the same cores, so together they cannot take more than the share.
    int cores = Environment.ProcessorCount;
    if (cpuPercent > 0 && cpuPercent < 100 && cores > 1 && cores <= 64) {
      int n = Math.Max(1, (int)Math.Round(cores * cpuPercent / 100.0));
      if (n < cores) { ulong mask = ((1UL << n) - 1UL) << (cores - n); e.Basic.LimitFlags |= 0x10; e.Basic.Affinity = new UIntPtr(mask); }   // JOB_OBJECT_LIMIT_AFFINITY
    }
    Set(9, e);                                 // JobObjectExtendedLimitInformation
    if (!AssignProcessToJobObject(job, GetCurrentProcess())) throw new Exception("AssignProcessToJobObject failed: " + Marshal.GetLastWin32Error());
  }
  public static uint Active() {
    int n = Marshal.SizeOf(typeof(ACCT));
    IntPtr p = Marshal.AllocHGlobal(n);
    try { if (!QueryInformationJobObject(job, 1, p, n, IntPtr.Zero)) return 0; return ((ACCT)Marshal.PtrToStructure(p, typeof(ACCT))).ActiveProcesses; }
    finally { Marshal.FreeHGlobal(p); }
  }
  public static double CpuSeconds() {
    int n = Marshal.SizeOf(typeof(ACCT));
    IntPtr p = Marshal.AllocHGlobal(n);
    try { if (!QueryInformationJobObject(job, 1, p, n, IntPtr.Zero)) return 0; ACCT a = (ACCT)Marshal.PtrToStructure(p, typeof(ACCT)); return (a.TotalUserTime + a.TotalKernelTime) / 1e7; }
    finally { Marshal.FreeHGlobal(p); }
  }
  public static void Kill() { TerminateJobObject(job, 1); }
}
'@
# compiling the C# costs seconds on an idle machine and minutes on a busy one: it is compiled once into <temp>/meridian-captures/CapJob-v3.dll and loaded from there afterwards
if (-not ('CapJob' -as [type])) {
  $dir = Join-Path ([System.IO.Path]::GetTempPath()) 'meridian-captures'
  $dll = Join-Path $dir 'CapJob-v3.dll'
  if (-not (Test-Path -LiteralPath $dll)) {
    try {
      New-Item -ItemType Directory -Force -Path $dir | Out-Null
      $tmp = "$dll.$PID.tmp"
      Add-Type -TypeDefinition $src -OutputAssembly $tmp
      Move-Item -LiteralPath $tmp -Destination $dll -Force -ErrorAction SilentlyContinue
      Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    } catch { }
  }
  if ((Test-Path -LiteralPath $dll) -and -not ('CapJob' -as [type])) { try { Add-Type -Path $dll } catch { } }
  if (-not ('CapJob' -as [type])) { Add-Type -TypeDefinition $src }
}

function Note([string]$state, [string]$reason) {
  if (-not $Registry) { return }
  try {
    $o = Get-Content -LiteralPath $Registry -Raw | ConvertFrom-Json
    $o | Add-Member -NotePropertyName state -NotePropertyValue $state -Force
    $o | Add-Member -NotePropertyName ended -NotePropertyValue $reason -Force
    $o | Add-Member -NotePropertyName endedAt -NotePropertyValue ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) -Force
    $o | Add-Member -NotePropertyName cpuSeconds -NotePropertyValue ([math]::Round([CapJob]::CpuSeconds(), 1)) -Force
    $o | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Registry -Encoding UTF8
  } catch { }
}

[CapJob]::Create($CpuPercent, ($Priority -eq 'BelowNormal'))
$list = @(Get-Content -LiteralPath $ArgsFile -Raw | ConvertFrom-Json)
Remove-Item -LiteralPath $ArgsFile -Force -ErrorAction SilentlyContinue
$quoted = ($list | ForEach-Object { if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ } }) -join ' '
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $Exe
$psi.Arguments = $quoted
$psi.UseShellExecute = $false
$psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
try { $null = [System.Diagnostics.Process]::Start($psi) } catch { [Console]::Error.WriteLine("capture-job: cannot start [$Exe] with [$quoted]: $($_.Exception.Message)"); Note 'ended' 'start-failed'; [CapJob]::Kill() }
$seen = $false
while ($true) {
  Start-Sleep -Milliseconds 1000
  $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  if ($now -ge $DeadlineMs) { Note 'ended' 'deadline'; break }
  if (-not (Get-Process -Id $ParentPid -ErrorAction SilentlyContinue)) { Note 'ended' 'parent-gone'; break }
  if ($IdleSeconds -gt 0 -and $Registry -and $seen) {
    # the launcher touches the registry file on every protocol call: a capture that has said nothing to its browser for this long is done or stuck
    try { $age = ([DateTime]::UtcNow - (Get-Item -LiteralPath $Registry).LastWriteTimeUtc).TotalSeconds; if ($age -gt $IdleSeconds) { Note 'ended' 'idle'; break } } catch { }
  }
  $active = [CapJob]::Active()
  if ($active -gt 1) { $seen = $true }
  elseif ($seen -and $active -le 1) { Note 'ended' 'browser-exited'; break }
}
[CapJob]::Kill()
