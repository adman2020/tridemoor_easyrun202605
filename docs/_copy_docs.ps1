$dir = "D:\AI\StrideMoor\docs"
$out = "C:\Users\Administered\.openclaw-study\workspace\docs"
if (!(Test-Path $out)) { New-Item -ItemType Directory -Path $out -Force | Out-Null }

$files = [System.IO.Directory]::GetFiles($dir)
$skipPrefix = @("04", "05", "06")

foreach ($f in $files) {
    $name = [System.IO.Path]::GetFileName($f)
    $skip = $false
    foreach ($p in $skipPrefix) { if ($name.StartsWith($p)) { $skip = $true } }
    if ($skip -or $name -eq "_verify_58.txt") { continue }
    
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $content = [System.Text.Encoding]::UTF8.GetString($bytes)
    
    # Use filename without Chinese (replace with index)
    $ext = [System.IO.Path]::GetExtension($f)
    $outFile = Join-Path $out "$name$ext"
    [System.IO.File]::WriteAllText($outFile, $content, [System.Text.Encoding]::UTF8)
    Write-Output "Copied: $name"
}
