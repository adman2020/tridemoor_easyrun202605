# 自动递增 Flutter 版本号（versionCode +1）
# 用法: pwsh scripts/bump_version.ps1 [major|minor|patch]
#
# version 格式: major.minor.patch+build
# 默认只 +build (+1)，可选升级 major/minor/patch

param(
    [ValidateSet('major','minor','patch','build')]
    [string]$Scope = 'build'
)

$pubspec = Join-Path $PSScriptRoot '..' 'pubspec.yaml'
$content = Get-Content $pubspec -Raw

if ($content -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    $build = [int]$Matches[4]

    switch ($Scope) {
        'major' { $major++; $minor = 0; $patch = 0 }
        'minor' { $minor++; $patch = 0 }
        'patch' { $patch++ }
        'build' { }
    }
    $build++

    $newVersion = "version: $major.$minor.$patch+$build"
    $oldVersion = $Matches[0]
    $content = $content -replace [regex]::Escape($oldVersion), $newVersion
    Set-Content $pubspec -Value $content -NoNewline

    Write-Host "✅ 版本号: $oldVersion → $newVersion"
    exit 0
} else {
    Write-Error "❌ 无法解析 pubspec.yaml 中的版本号"
    exit 1
}
