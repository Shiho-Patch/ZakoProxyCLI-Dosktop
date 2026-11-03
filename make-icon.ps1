Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSCommandPath
$out = Join-Path $root 'assets'
New-Item -ItemType Directory -Force -Path $out | Out-Null

# Draws the ZakoAI mark at an arbitrary size, mirroring web/public/favicon.svg.
function New-Zako([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.PixelOffsetMode = 'HighQuality'
    $g.Clear([System.Drawing.Color]::Transparent)

    $rect = New-Object System.Drawing.RectangleF([single]0, [single]0, [single]$size, [single]$size)
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(255, 255, 122, 174),
        [System.Drawing.Color]::FromArgb(255, 255, 191, 63),
        45.0)
    $r = $size * 0.30
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $path.AddArc(0, 0, $d, $d, 180, 90)
    $path.AddArc($size - $d, 0, $d, $d, 270, 90)
    $path.AddArc($size - $d, $size - $d, $d, $d, 0, 90)
    $path.AddArc(0, $size - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    $g.FillPath($grad, $path)

    $white = [System.Drawing.Brushes]::White
    # fish body
    $body = New-Object System.Drawing.RectangleF([single]($size * 0.14), [single]($size * 0.28), [single]($size * 0.60), [single]($size * 0.45))
    $g.FillEllipse($white, $body)
    # tail
    $tail = @(
        (New-Object System.Drawing.PointF(($size * 0.70), [single]($size * 0.50))),
        (New-Object System.Drawing.PointF(($size * 0.88), [single]($size * 0.34))),
        (New-Object System.Drawing.PointF(($size * 0.88), [single]($size * 0.66)))
    )
    $g.FillPolygon($white, $tail)
    # eye
    $eye = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 176, 32, 90))
    $g.FillEllipse($eye, [single]($size * 0.24), [single]($size * 0.40), [single]($size * 0.13), [single]($size * 0.13))
    $g.FillEllipse($white, [single]($size * 0.265), [single]($size * 0.425), [single]($size * 0.045), [single]($size * 0.045))

    $g.Dispose()
    return $bmp
}

$sizes = @{ 'zako16.png' = 16; 'zako32.png' = 32; 'zako48.png' = 48; 'zako64.png' = 64;
            'zako128.png' = 128; 'zako256.png' = 256; 'zako512.png' = 512 }
foreach ($name in $sizes.Keys) {
    $bmp = New-Zako $sizes[$name]
    $bmp.Save((Join-Path $out $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

# Multi-resolution .ico assembled from PNG payloads (Vista+ ICO container).
function New-Ico([string[]]$files, [string]$target) {
    $images = @()
    foreach ($f in $files) {
        $bmp = [System.Drawing.Image]::FromFile($f)
        $w = $bmp.Width; $h = $bmp.Height
        $bmp.Dispose()
        $bytes = [System.IO.File]::ReadAllBytes($f)
        $images += ,@($w, $h, $bytes)
    }
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)
    $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$images.Count)
    $offset = 6 + 16 * $images.Count
    foreach ($img in $images) {
        $w = $img[0]; $h = $img[1]; $data = $img[2]
        if ($w -ge 256) { $bw.Write([byte]0) } else { $bw.Write([byte]$w) }
        if ($h -ge 256) { $bw.Write([byte]0) } else { $bw.Write([byte]$h) }
        $bw.Write([byte]0); $bw.Write([byte]0)
        $bw.Write([uint16]1); $bw.Write([uint16]32)
        $bw.Write([uint32]$data.Length); $bw.Write([uint32]$offset)
        $offset += $data.Length
    }
    foreach ($img in $images) { $bw.Write($img[2]) }
    $bw.Flush()
    [System.IO.File]::WriteAllBytes($target, $ms.ToArray())
    $bw.Dispose(); $ms.Dispose()
}
New-Ico @((Join-Path $out 'zako16.png'), (Join-Path $out 'zako32.png'), (Join-Path $out 'zako48.png'), (Join-Path $out 'zako64.png'), (Join-Path $out 'zako128.png'), (Join-Path $out 'zako256.png')) (Join-Path $out 'zako.ico')

# Intermediate for ImageMagick conversion to the @mipmap ic_launcher.png set.
Get-ChildItem $out | Select-Object Name, Length | Format-Table -AutoSize | Out-String



