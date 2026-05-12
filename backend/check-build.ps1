# Check if build succeeded
$files = Get-ChildItem -Filter "server*" -ErrorAction SilentlyContinue
Write-Host "Files found:" -ForegroundColor Cyan
$files | ForEach-Object { Write-Host "$($_.Name) ($($_.Length) bytes)" }

# Try to run
if ($files) {
    $file = $files | Select-Object -First 1
    Write-Host "`nAttempting to run: $file.FullName" -ForegroundColor Yellow
    $file.StartProcess("-NoNewWindow") | Out-Null
    Write-Host "Process started" -ForegroundColor Green
}
