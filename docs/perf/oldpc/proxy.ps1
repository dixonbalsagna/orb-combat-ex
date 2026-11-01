# The old PC's half of the test (Performance and Platform): a small web relay that runs ON THE OLD PC and listens on its own loopback address only (127.0.0.1), passing every request to the test server on
# the other PC. Why: the game will not start at all on a plain http address ("Secure Context" is missing), and treats only 127.0.0.1 / localhost as a local page (otherwise it drops ?tiles=1 and ?meteor=).
# A page opened at http://127.0.0.1:8780/ on the old PC is both. No installation, no administrator rights, no firewall prompt (it listens on loopback, and only makes an outgoing request).
#
#   powershell -ExecutionPolicy Bypass -File proxy.ps1 -Target http://10.0.0.135:8780          (the address the server on the other PC printed, without /oldpc/)
#   then open  http://127.0.0.1:8780/oldpc/  in Chrome or Edge on this PC.
# Ctrl-C or closing the window stops it. It refuses everything except /oldpc/ and /game/ paths and the report POST, and it ends by itself after -Minutes (default 45).
param(
  [Parameter(Mandatory = $true)][string]$Target,
  [int]$Port = 8780,
  [int]$Minutes = 45
)
$ErrorActionPreference = 'Stop'
$Target = $Target.TrimEnd('/')
if ($Target -notmatch '^http://(10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+|172\.(1[6-9]|2\d|3[01])\.\d+\.\d+|127\.0\.0\.1):\d+$') { throw "-Target must be http://<a private network address>:<port>, got $Target" }
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()
Write-Host "Relaying http://127.0.0.1:$Port/ -> $Target  (open http://127.0.0.1:$Port/oldpc/ ). Ctrl-C stops it."
$end = (Get-Date).AddMinutes($Minutes)
$buf = New-Object byte[] 262144
while ((Get-Date) -lt $end) {
  $task = $listener.GetContextAsync()
  while (-not $task.Wait(1000)) { if ((Get-Date) -ge $end) { break } }
  if (-not $task.IsCompleted) { break }
  $ctx = $task.Result
  $req = $ctx.Request; $res = $ctx.Response
  try {
    $path = $req.Url.PathAndQuery
    $okPath = ($path -like '/oldpc/*') -or ($path -eq '/oldpc') -or ($path -like '/game/*')
    if (-not $okPath -or ($req.HttpMethod -ne 'GET' -and $req.HttpMethod -ne 'HEAD' -and -not ($req.HttpMethod -eq 'POST' -and $path -eq '/oldpc/report'))) { $res.StatusCode = 404; $res.Close(); continue }
    $wr = [System.Net.HttpWebRequest]::Create($Target + $path)
    $wr.Method = $req.HttpMethod
    $wr.AllowAutoRedirect = $false
    $wr.Timeout = 120000
    $wr.ReadWriteTimeout = 120000
    if ($req.HttpMethod -eq 'POST') {
      $wr.ContentType = $req.ContentType
      $out = $wr.GetRequestStream(); $req.InputStream.CopyTo($out); $out.Close()
    }
    try { $resp = $wr.GetResponse() } catch [System.Net.WebException] { $resp = $_.Exception.Response; if ($null -eq $resp) { throw } }
    $res.StatusCode = [int]$resp.StatusCode
    $res.ContentType = $resp.ContentType
    $res.AddHeader('Cache-Control', 'no-store')
    if ($req.HttpMethod -ne 'HEAD') {
      $res.SendChunked = $true
      $in = $resp.GetResponseStream()
      while (($n = $in.Read($buf, 0, $buf.Length)) -gt 0) { $res.OutputStream.Write($buf, 0, $n) }
      $in.Close()
    }
    $resp.Close()
    $res.Close()
  } catch {
    try { $res.StatusCode = 502; $res.Close() } catch { }
    Write-Host ("relay error on {0}: {1}" -f $req.RawUrl, $_.Exception.Message)
  }
}
$listener.Stop()
Write-Host 'Stopped.'
