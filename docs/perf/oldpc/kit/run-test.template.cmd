<# : batch portion
@echo off
rem ONE-CLICK TEST for the old PC (Performance and Platform). Double-click this file. It needs no installation, no administrator rights, no download and no network.
rem It is a batch file with PowerShell inside; build-kit.mjs fills in the page. Read it: it is plain text.
setlocal
set "KIT=%~dp0"
set "SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create([System.IO.File]::ReadAllText($env:SELF, [System.Text.Encoding]::UTF8)))"
echo.
pause
exit /b
: end batch portion / begin PowerShell #>

$ErrorActionPreference = 'Stop'
$kit = $env:KIT.TrimEnd('\')
$parts = Join-Path $kit 'parts'
New-Item -ItemType Directory -Force -Path $parts | Out-Null
$log = New-Object System.Collections.ArrayList
function Say([string]$s) { Write-Host $s; [void]$log.Add($s) }
function J([string]$s) { return ($s | ConvertTo-Json -Compress) }

Write-Host ''
Write-Host '  Orb Combat EX - old PC test (a speed reading, never a flash reading)'
Write-Host '  -----------------------------------------------------------------'
Write-Host '  What this does: (1) plays a match and a rematch, then three short matches, all with no window, to check this processor and time it;'
Write-Host '  (2) opens the game in your browser for two minutes, to time the graphics.'
Write-Host '  It listens only on THIS PC (127.0.0.1), opens no network port, changes nothing, installs nothing,'
Write-Host '  and writes ONE result file next to this one, which you bring back. Nothing is uploaded.'
Write-Host ''
Write-Host '  Before you start:  only you watch the screen (nobody else in the room);  no photos, screenshots or recordings;'
Write-Host '  close games and other browser windows;  plug the PC in the wall.'
Write-Host '  The game shows its own flashing-effects warning: read it, use Reduce flashing if you want.'
Write-Host ''
Write-Host '  Press Enter to start.'
[void][Console]::ReadLine()

# ---------- machine
$cpu = ''; $ram = ''; $os = ''
try { $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim() } catch { }
try { $ram = [string][math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1) + ' GB' } catch { }
try { $os = (Get-CimInstance Win32_OperatingSystem).Caption } catch { }
$gpus = ''
try { $gpus = ((Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name + ' (driver ' + $_.DriverVersion + ')' }) -join '; ') } catch { }
Say ("machine: $cpu | $ram | $os")
Say ("graphics: $gpus")

# ---------- part 1: the native sim (Godot, no window)
$simPath = Join-Path $parts 'sim.json'
$godot = Join-Path $kit 'godot\Godot_v4.7.2-stable_win64_console.exe'
$simText = 'null'
$twopcText = 'null'
$twopcExit = -1
$build = '@@BUILD@@'
if (Test-Path -LiteralPath $godot) {
  Say ''
  Say 'Part 1 of 2: the sim, with no window (about a minute or two)...'
  if (Test-Path -LiteralPath $simPath) { Remove-Item -LiteralPath $simPath -Force }
  if (-not (Test-Path -LiteralPath (Join-Path $kit 'project\.godot\global_script_class_cache.cfg'))) {
    Say '  (first run on this folder: Godot reads the project once, about a minute)'
    $ErrorActionPreference = 'Continue'
    & $godot @('--headless', '--path', (Join-Path $kit 'project'), '--import', '--quit') 2>&1 | Out-Null
    $ErrorActionPreference = 'Stop'
  }
  # 1a: Netcode's two-PC check (net/tools/two_pc_check.gd): one match and a rematch in one process, a report of check numbers; headless, no window, no network. Run at below-normal priority as its own kit does.
  $twoPath = Join-Path $parts 'twopc.txt'
  if (Test-Path -LiteralPath $twoPath) { Remove-Item -LiteralPath $twoPath -Force }
  if (Test-Path -LiteralPath (Join-Path $kit 'project\net\tools\two_pc_check.gd')) {
    Say '  1a: the two-processor check (a minute or two)...'
    $a2 = '--headless --path "' + (Join-Path $kit 'project') + '" --script res://net/tools/two_pc_check.gd -- --out="' + $twoPath + '" --build=' + $build + ' --ticks=3600 --timeout=900'
    $pr = Start-Process -FilePath $godot -ArgumentList $a2 -NoNewWindow -PassThru
    $null = $pr.Handle   # without this, ExitCode reads empty after WaitForExit in Windows PowerShell 5.1
    try { $pr.PriorityClass = 'BelowNormal' } catch { }
    $pr.WaitForExit()
    $twopcExit = $(if ($null -ne $pr.ExitCode) { [int]$pr.ExitCode } else { -1 })
    if (Test-Path -LiteralPath $twoPath) { $twopcText = (J ([System.IO.File]::ReadAllText($twoPath, [System.Text.Encoding]::UTF8))); Say ('  1a: finished, exit ' + $twopcExit) } else { Say '  1a wrote no report (see the lines above).' }
  } else { Say '  1a skipped: the project folder has no net\tools\two_pc_check.gd.' }
  Say '  1b: the speed run (about a minute)...'
  $args1 = @('--headless', '--path', (Join-Path $kit 'project'), '--script', 'res://oldpc_sim.gd', '--', ('--out=' + $simPath))
  $ErrorActionPreference = 'Continue'   # Godot writes warnings to stderr; they are not errors
  & $godot @args1 2>&1 | ForEach-Object { Say ([string]$_) }
  $ErrorActionPreference = 'Stop'
  if (Test-Path -LiteralPath $simPath) { $simText = [System.IO.File]::ReadAllText($simPath, [System.Text.Encoding]::UTF8) } else { Say 'Part 1 wrote no result (see the lines above).' }
} else {
  Say 'Part 1 skipped: godot\Godot_v4.7.2-stable_win64_console.exe is not in this folder.'
}

# ---------- part 2: the browser page, served from this PC's loopback address
$pageText = @'
@@PAGE@@
'@
$site = Join-Path $kit 'game'
$browserText = 'null'
if (-not (Test-Path -LiteralPath (Join-Path $site 'index.html'))) {
  Say 'Part 2 skipped: game\index.html is not in this folder.'
} else {
  Say ''
  Say 'Part 2 of 2: the game in your browser (about four minutes). A page opens; follow it.'
  $mime = @{ '.html' = 'text/html; charset=utf-8'; '.js' = 'text/javascript; charset=utf-8'; '.wasm' = 'application/wasm'; '.pck' = 'application/octet-stream'; '.png' = 'image/png'; '.json' = 'application/json'; '.css' = 'text/css'; '.webmanifest' = 'application/manifest+json'; '.svg' = 'image/svg+xml'; '.ogg' = 'audio/ogg'; '.wav' = 'audio/wav'; '.mp3' = 'audio/mpeg' }
  $listener = $null; $port = 0
  foreach ($p in 8790..8799) {
    try { $l = New-Object System.Net.HttpListener; $l.Prefixes.Add("http://127.0.0.1:$p/"); $l.Start(); $listener = $l; $port = $p; break } catch { }
  }
  if ($null -eq $listener) { Say 'Part 2 skipped: no free port on 127.0.0.1 (8790 to 8799).' }
  else {
    $pageBytes = [System.Text.Encoding]::UTF8.GetBytes($pageText.Replace("`r`n", "`n"))
    $siteFull = [System.IO.Path]::GetFullPath($site).TrimEnd('\') + '\'
    $url = "http://127.0.0.1:$port/oldpc/"
    Say ("Open this page if it does not open by itself:  $url")
    if (-not $env:OLDPC_NO_OPEN) { Start-Process $url }   # OLDPC_NO_OPEN is for trying the kit without a browser window
    $end = (Get-Date).AddMinutes(25); $stopAt = $null; $got = $false
    $buf = New-Object byte[] 262144
    while ((Get-Date) -lt $end) {
      if ($null -ne $stopAt -and (Get-Date) -ge $stopAt) { break }
      $task = $listener.GetContextAsync()
      while (-not $task.Wait(1000)) { if ((Get-Date) -ge $end -or ($null -ne $stopAt -and (Get-Date) -ge $stopAt)) { break } }
      if (-not $task.IsCompleted) { break }
      $ctx = $task.Result; $req = $ctx.Request; $res = $ctx.Response
      try {
        $path = [System.Uri]::UnescapeDataString($req.Url.AbsolutePath)
        $res.AddHeader('Cache-Control', 'no-store')
        if ($req.HttpMethod -eq 'POST' -and $path -eq '/oldpc/report') {
          $ms = New-Object System.IO.MemoryStream; $req.InputStream.CopyTo($ms)
          $txt = [System.Text.Encoding]::UTF8.GetString($ms.ToArray())
          if ($txt.Length -lt 4000000 -and $txt.TrimStart().StartsWith('{')) { $browserText = $txt; $got = $true; $stopAt = (Get-Date).AddSeconds(20) }
          $b = [System.Text.Encoding]::UTF8.GetBytes('{"ok":true}'); $res.ContentType = 'application/json'; $res.OutputStream.Write($b, 0, $b.Length); $res.Close(); continue
        }
        if ($req.HttpMethod -ne 'GET' -and $req.HttpMethod -ne 'HEAD') { $res.StatusCode = 405; $res.Close(); continue }
        if ($path -eq '/oldpc' -or $path -eq '/oldpc/') { $res.ContentType = $mime['.html']; $res.ContentLength64 = $pageBytes.Length; if ($req.HttpMethod -ne 'HEAD') { $res.OutputStream.Write($pageBytes, 0, $pageBytes.Length) }; $res.Close(); continue }
        if ($path -eq '/oldpc/ping') { $b = [System.Text.Encoding]::UTF8.GetBytes('ok'); $res.ContentType = 'text/plain'; $res.OutputStream.Write($b, 0, $b.Length); $res.Close(); continue }
        if ($path.StartsWith('/game/')) {
          $rel = $path.Substring(6); if ($rel -eq '') { $rel = 'index.html' }
          $file = [System.IO.Path]::GetFullPath((Join-Path $site ($rel.Replace('/', '\'))))
          if (-not $file.StartsWith($siteFull) -or -not (Test-Path -LiteralPath $file -PathType Leaf)) { $res.StatusCode = 404; $res.Close(); continue }
          $ext = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
          $res.ContentType = $(if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' })
          $fi = Get-Item -LiteralPath $file
          $res.ContentLength64 = $fi.Length
          if ($req.HttpMethod -ne 'HEAD') {
            $fs = [System.IO.File]::OpenRead($file)
            try { while (($n = $fs.Read($buf, 0, $buf.Length)) -gt 0) { $res.OutputStream.Write($buf, 0, $n) } } finally { $fs.Close() }
          }
          $res.Close(); continue
        }
        $res.StatusCode = 404; $res.Close()
      } catch {
        try { $res.Abort() } catch { }
      }
    }
    $listener.Stop()
    if (-not $got) { Say 'Part 2 sent no result (closed early, or 25 minutes passed).' }
  }
}

# ---------- the one result file
$stamp = (Get-Date).ToString('yyyyMMdd-HHmm')
$resultPath = Join-Path $kit ("oldpc-result-$stamp.json")
$summary = ($log -join "`n")
# RL-230: the headless report names CPU, OS and numbers only; nothing in the file may carry a path, a user name or the PC's name
foreach ($pair in @(@($kit, '<kit folder>'), @($env:USERPROFILE, '<profile>'), @($env:USERNAME, '<user>'), @($env:COMPUTERNAME, '<pc>'))) { if ($pair[0] -and $pair[0].Length -ge 3) { $summary = $summary.Replace($pair[0], $pair[1]) } }
$json = '{"kit":"oldpc-kit","when":' + (J (Get-Date).ToString('o')) + ',"cpu":' + (J $cpu) + ',"ram":' + (J $ram) + ',"os":' + (J $os) + ',"graphics":' + (J $gpus) + ',"summary":' + (J $summary) + ',"twopc_exit":' + $twopcExit + ',"twopc":' + $twopcText + ',"sim":' + $simText + ',"browser":' + $browserText + '}'
[System.IO.File]::WriteAllText($resultPath, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ''
Write-Host '  Done. Bring this ONE file back:'
Write-Host ('    ' + $resultPath)
Write-Host '  Then you can delete the folder "parts" and this window. Nothing else was written (Godot keeps a small log in your AppData folder).'
