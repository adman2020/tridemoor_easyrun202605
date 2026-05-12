# 驰陌 StrideMoor — PowerShell 启动优化脚本
# 用法：右键 → 使用 PowerShell 运行

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PowerShell 启动诊断与优化" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 检测 Profile 加载时间
Write-Host "[1/4] 检测 Profile 加载时间..." -ForegroundColor Yellow
$profiles = @(
    $PROFILE.AllUsersAllHosts,
    $PROFILE.AllUsersCurrentHost,
    $PROFILE.CurrentUserAllHosts,
    $PROFILE.CurrentUserCurrentHost
)

$hasProfile = $false
foreach ($p in $profiles) {
    if (Test-Path $p) {
        $hasProfile = $true
        $size = (Get-Item $p).Length
        Write-Host "  找到 Profile: $p" -ForegroundColor White
        Write-Host "  大小: $size bytes" -ForegroundColor Gray
        
        # 测量加载时间
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        . $p
        $sw.Stop()
        Write-Host "  加载耗时: $($sw.ElapsedMilliseconds)ms" -ForegroundColor $(if($sw.ElapsedMilliseconds -gt 500){"Red"}else{"Green"})
        Write-Host ""
    }
}

if (-not $hasProfile) {
    Write-Host "  [OK] 没有找到 Profile 脚本" -ForegroundColor Green
}

# 2. 检测已加载模块
Write-Host "[2/4] 检测已加载模块..." -ForegroundColor Yellow
$modules = Get-Module
Write-Host "  已加载模块数: $($modules.Count)" -ForegroundColor White
$modules | ForEach-Object {
    Write-Host "    - $($_.Name) ($($_.Version))" -ForegroundColor Gray
}
Write-Host ""

# 3. 检测自动加载模块
Write-Host "[3/4] 检测自动加载模块配置..." -ForegroundColor Yellow
$autoLoadPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
if (Test-Path $autoLoadPath) {
    Write-Host "  [警告] 发现模块日志策略，可能影响性能" -ForegroundColor Yellow
} else {
    Write-Host "  [OK] 未发现异常模块日志策略" -ForegroundColor Green
}
Write-Host ""

# 4. 优化建议
Write-Host "[4/4] 优化建议" -ForegroundColor Yellow
Write-Host ""

if ($hasProfile) {
    Write-Host "  问题：Profile 脚本导致启动慢" -ForegroundColor Red
    Write-Host "  解决方案：" -ForegroundColor White
    Write-Host "    1. 编辑 Profile 文件，注释掉不需要的模块" -ForegroundColor Gray
    Write-Host "    2. 将模块加载改为按需加载（延迟加载）" -ForegroundColor Gray
    Write-Host "    3. 使用 'powershell -NoProfile' 跳过 Profile" -ForegroundColor Gray
    Write-Host ""
    
    $response = Read-Host "  是否备份并清空 Profile？(y/n)"
    if ($response -eq "y" -or $response -eq "Y") {
        $backupDir = "$env:USERPROFILE\Documents\PowerShellProfileBackup"
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        
        foreach ($p in $profiles) {
            if (Test-Path $p) {
                $backupFile = "$backupDir\$(Split-Path $p -Leaf)_$(Get-Date -Format 'yyyyMMdd_HHmmss').bak"
                Copy-Item $p $backupFile -Force
                Write-Host "  已备份: $backupFile" -ForegroundColor Green
                Clear-Content $p -Force
                Write-Host "  已清空: $p" -ForegroundColor Green
            }
        }
        Write-Host "  [OK] Profile 已备份并清空，重启 PowerShell 生效" -ForegroundColor Green
    }
} else {
    Write-Host "  [OK] 没有 Profile 脚本，启动慢可能是其他原因" -ForegroundColor Green
    Write-Host "  建议：" -ForegroundColor White
    Write-Host "    1. 检查杀毒软件是否扫描 PowerShell" -ForegroundColor Gray
    Write-Host "    2. 检查 .NET 程序集是否需要重新编译" -ForegroundColor Gray
    Write-Host "    3. 尝试以管理员身份运行 PowerShell" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  诊断完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
pause
