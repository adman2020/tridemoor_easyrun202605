$dir = [System.IO.DirectoryInfo]::new("D:\AI\StrideMoor\docs")
$files = $dir.GetFiles() | Sort-Object Name
$skipPrefix = @("04", "05", "06")
$fileIdx = 0
foreach ($f in $files) {
    $shouldSkip = $false
    foreach ($p in $skipPrefix) { if ($f.Name.StartsWith($p)) { $shouldSkip = $true } }
    if ($shouldSkip -or $f.Name -eq "_verify_58.txt") { continue }
    $fileIdx++
    Write-Output "========== File $fileIdx =========="
    Write-Output "Name: $($f.Name)"
    Write-Output "Size: $($f.Length) bytes"
    Write-Output "----------------------"
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $lines = $content -split "`n"
    # Show first 50 lines of each file
    for ($i = 0; $i -lt [Math]::Min(50, $lines.Length); $i++) {
        $line = $lines[$i]
        # Try to decode and display
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($line)
        $decoded = [System.Text.Encoding]::GetEncoding(936).GetString($bytes)
        if ($decoded.Trim() -ne "") {
            Write-Output $decoded
        }
    }
    if ($lines.Length -gt 50) {
        Write-Output "... (truncated, total $($lines.Length) lines)"
    }
    Write-Output ""
}
