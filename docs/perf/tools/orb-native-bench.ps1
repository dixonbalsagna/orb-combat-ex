# Orb Combat EX: a native frame-time bench you can run by hand. It OPENS A GAME WINDOW (about 1 to 2 minutes a pass) and measures what no headless run can: the real
# frame time with the graphics card, draw calls and the GPU's own timers. Nothing is installed, nothing is sent anywhere, no file in the project is changed;
# the result is one text file on your Desktop that you can paste to the EP.
#
# Easiest: double-click docs\perf\tools\orb-native-bench.cmd (it calls this file). Or from a terminal in the project folder:
#   powershell -ExecutionPolicy Bypass -File docs\perf\tools\orb-native-bench.ps1
# Before you start: close games and browsers if you can (the number is only good on a quiet PC), plug a laptop in, and do not touch the keyboard or mouse while a
# window is open. The script says how busy the PC was before and after, so a busy run can be told apart.
#
# Options:   -Godot <path to Godot_v4.7.2-stable_win64_console.exe>   (found by itself in the usual places)
#            -Frames 3600     frames per pass (60 s of game at 60 per second)
#            -Seed 4          the AI-against-AI match to play (the same match every time)
#            -Resolution 1280x720
#            -OnlyDefaultGpu  skip the second pass on the other graphics adapter
#            -DryRun          print what it would do and stop (opens nothing)
#            -Headless        run with no window (CPU side only; for testing the script)
param(
  [string]$Godot = '',
  [int]$Frames = 3600,
  [int]$Seed = 4,
  [string]$Resolution = '1280x720',
  [switch]$OnlyDefaultGpu,
  [switch]$DryRun,
  [switch]$Headless
)
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
if (-not (Test-Path (Join-Path $project 'project.godot'))) { throw "no project.godot at ${project} - run this from the Orb Combat EX folder" }

# --- find Godot 4.7.2
if (-not $Godot) {
  $cands = @(
    $env:GODOT,
    (Join-Path $env:LOCALAPPDATA 'Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64.exe'),
    'C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe',
    'C:\Godot\Godot_v4.7.2-stable_win64_console.exe'
  ) | Where-Object { $_ -and (Test-Path $_) }
  if ($cands) { $Godot = @($cands)[0] }
}
if (-not $Godot -or -not (Test-Path $Godot)) { throw "Godot 4.7.2 not found. Pass it: -Godot C:\path\to\Godot_v4.7.2-stable_win64_console.exe" }

# --- the machine
function Load-Now { [math]::Round((Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 5 | ForEach-Object { $_.CounterSamples[0].CookedValue } | Measure-Object -Average).Average) }
$cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1)
$gpus = @(Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Basic|Remote|Virtual' })
$os = Get-CimInstance Win32_OperatingSystem
$power = (powercfg /getactivescheme) -join ' '
$stamp = Get-Date -Format 'yyyy-MM-dd-HHmm'
$out = Join-Path ([Environment]::GetFolderPath('Desktop')) "orb-native-bench-$stamp.txt"
$lines = New-Object System.Collections.Generic.List[string]
function Say($t) { Write-Host $t; $lines.Add($t) }
Say "Orb Combat EX native bench, $stamp"
Say "commit: $((& git -C $project rev-parse --short HEAD 2>$null) -join '')"
Say "CPU: $($cpu.Name) ($($cpu.NumberOfCores) cores, $($cpu.NumberOfLogicalProcessors) threads)"
Say ("RAM: {0:N0} GB   OS: {1}" -f ($os.TotalVisibleMemorySize / 1MB), $os.Caption)
$i = 0; foreach ($g in $gpus) { Say "GPU $i`: $($g.Name)  driver $($g.DriverVersion)"; $i++ }
Say "power plan: $power"
Say "Godot: $Godot   frames $Frames  seed $Seed  resolution $Resolution"

$passes = @(@{ name = 'default GPU'; extra = @() })
if (-not $OnlyDefaultGpu -and $gpus.Count -gt 1) { for ($k = 0; $k -lt $gpus.Count; $k++) { $passes += @{ name = "adapter index $k (Godot numbers adapters its own way: the first BENCH line below names the one it really used)"; extra = @('--gpu-index', "$k") } } }
if ($DryRun) { Say 'DRY RUN: would run these passes, then stop:'; foreach ($p in $passes) { Say "  $($p.name): $Godot --path `"$project`" $($p.extra -join ' ') --fixed-fps 60 --resolution $Resolution -- --seed=$Seed --frames=$Frames --bench" }; Say "result file would be: $out"; return }

# --- import once, headless, so the first pass is not slowed by it
Write-Host 'Preparing the project (a headless import, no window)...'
& $Godot --headless --path $project --import 2>&1 | Out-Null

foreach ($p in $passes) {
  $before = Load-Now
  Say ''
  Say "=== pass: $($p.name)   (PC busy before: $before% )"
  if ($before -gt 40) { Say "NOTE: the PC was $before% busy before this pass; close other programs and rerun for a number you can trust." }
  $args2 = @() + $(if ($Headless) { @('--headless') } else { @() }) + @('--path', $project) + $p.extra + @('--fixed-fps', '60', '--resolution', $Resolution, '--', "--seed=$Seed", "--frames=$Frames", '--bench')
  Write-Host 'A game window opens now and closes by itself. Please do not touch anything.'
  $text = & $Godot @args2 2>&1 | Out-String
  $after = Load-Now
  foreach ($l in ($text -split "`r?`n")) { if ($l -match '^BENCH|gameplay hash') { Say $l } }
  Say "PC busy after: $after%"
  if (-not ($text -match 'BENCH')) { Say 'No BENCH lines came back: the game did not run to its end. Send the EP this file anyway.' }
}
Say ''
Say 'How to read it: "frame ms" is the time between frames with vsync off (smaller is better; 16.7 ms is 60 fps). "render gpu ms" is the graphics card. "draw calls" is how many draws a frame makes.'
$lines | Set-Content -Encoding UTF8 $out
Write-Host "`nDone. The result is on your Desktop: $out`nPaste its contents to the EP."
