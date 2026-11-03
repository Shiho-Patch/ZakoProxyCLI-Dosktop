param(
    [string]$Root = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [string]$Cab = 'D:\zkbuild\cab\zakoai-proxy.cab'
)

$ErrorActionPreference = 'Stop'
$dist   = Join-Path $Root 'dist\ZakoAI-Proxy-Windows'
$srcExe = Join-Path $Root 'windows\ZakoAI.Desktop.exe'
$outExe = Join-Path $dist 'ZakoAI.Desktop.exe'

$marker = 'KA/OBC__AKZ'
$slot   = '@@@@' * 6 + '@@@'

# 1. Append the server cabinet (payload) to the launcher image.
$exeBytes = [System.IO.File]::ReadAllBytes($srcExe)
$cabBytes = [System.IO.File]::ReadAllBytes($Cab)
$exe = New-Object byte[] ($exeBytes.Length + $cabBytes.Length)
[Array]::Copy($exeBytes, 0, $exe, 0, $exeBytes.Length)
[Array]::Copy($cabBytes, 0, $exe, $exeBytes.Length, $cabBytes.Length)

# 2. Patch the 25-character slot so unpack-sfx.ps1 can find the payload length.
$text = [System.Text.Encoding]::Unicode.GetString($exe)
$idx = $text.IndexOf($slot, [System.StringComparison]::Ordinal)
if ($idx -lt 0) { throw 'launcher payload slot not found' }
$trailer = '{0}?len={1:D10}' -f $marker, $cabBytes.Length
$bytes = [System.Text.Encoding]::Unicode.GetBytes($trailer)
[Array]::Copy($bytes, 0, $exe, $idx * 2, $bytes.Length)

[System.IO.File]::WriteAllBytes($outExe, $exe)
'{0} -> {1} bytes (payload {2})' -f $outExe, $exe.Length, $cabBytes.Length
