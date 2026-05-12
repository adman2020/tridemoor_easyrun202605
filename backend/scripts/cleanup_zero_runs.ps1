# 清理 0.0km 废记录定时脚本
# 由 Windows 计划任务调用（每日凌晨 3:00）

$logFile = "D:\AI\StrideMoor\backend\scripts\cleanup_zero_runs.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 检查 MySQL 是否运行
$container = docker ps --filter "name=stridemoor-mysql" --format "{{.Names}}" 2>&1
if (-not $container) {
    "$timestamp - [ERROR] MySQL container not running" | Out-File -Encoding utf8 $logFile -Append
    exit 1
}

# 执行清理
$result = docker exec stridemoor-mysql mysql -u stridemoor -p'stridemoor_pass_2026' stridemoor --default-character-set=utf8mb4 -N -B -e "
DELETE FROM runs WHERE (total_distance IS NULL OR total_distance = 0) AND total_time IS NULL;
SELECT ROW_COUNT() as deleted;" 2>&1

if ($LASTEXITCODE -eq 0) {
    "$timestamp - [OK] 已清理 $result 条废记录" | Out-File -Encoding utf8 $logFile -Append
} else {
    "$timestamp - [ERROR] $result" | Out-File -Encoding utf8 $logFile -Append
}
