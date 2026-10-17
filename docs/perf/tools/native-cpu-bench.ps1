# Native CPU-side cost of the game, headless (no window, no GPU: the dummy renderer), at below-normal priority, one Godot at a time.
# What it measures: sim tick ms, fx+camera ms, view-update ms (the GDScript that builds each frame's nodes and instance data). What it cannot: draw calls, GPU time, VRAM.
# Usage (from the repo root or a scratch copy of it):
#   powershell -File docs/perf/tools/native-cpu-bench.ps1 -Project <project folder> -Seed 4 -Frames 3600 -Out <log file> [-Godot <godot console exe>] [-LimitS 900]
param(
  [Parameter(Mandatory = $true)][string]$Project,
  [int]$Seed = 4,
  [int]$Frames = 3600,
  [Parameter(Mandatory = $true)][string]$Out,
  [string]$Godot = 'C:\Users\itsha\AppData\Local\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe',
  [int]$LimitS = 900
)
$before = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3 | ForEach-Object { $_.CounterSamples[0].CookedValue } | Measure-Object -Average).Average
$args2 = @('--headless', '--path', $Project, '--fixed-fps', '60', '--', "--seed=$Seed", "--frames=$Frames", '--bench')
$p = Start-Process -FilePath $Godot -ArgumentList $args2 -PassThru -NoNewWindow -RedirectStandardOutput $Out -RedirectStandardError ($Out + '.err')
try { $p.PriorityClass = 'BelowNormal' } catch {}
if (-not $p.WaitForExit($LimitS * 1000)) { Stop-Process -Id $p.Id -Force; Add-Content $Out 'TIMEOUT'; exit 124 }
$after = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3 | ForEach-Object { $_.CounterSamples[0].CookedValue } | Measure-Object -Average).Average
Add-Content $Out ("LOAD before {0:N0}% after {1:N0}% (valid only when both are under 60%)" -f $before, $after)
