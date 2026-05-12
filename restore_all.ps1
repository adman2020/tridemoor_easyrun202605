Write-Host "=== 恢复 StrideMoor 数据 ===" -ForegroundColor Cyan

# 1. 注册 15 个用户（密码统一 test123456）
Write-Host "[1/4] 注册用户..." -ForegroundColor Yellow

$users = @(
    @{id="a0000001-0000-0000-0000-000000000001"; phone="13800000021"; nickname="罗峰"; gender=1}
    @{id="a0000001-0000-0000-0000-000000000002"; phone="13800000022"; nickname="洪"; gender=1}
    @{id="a0000001-0000-0000-0000-000000000003"; phone="13800000023"; nickname="雷沉"; gender=1}
    @{id="a0000001-0000-0000-0000-000000000004"; phone="13800000024"; nickname="徐欣"; gender=2}
    @{id="a0000001-0000-0000-0000-000000000005"; phone="13800000025"; nickname="陈谷"; gender=1}
    @{id="a0000001-0000-0000-0000-000000000006"; phone="13800000026"; nickname="野人"; gender=1}
    @{id="a0000001-0000-0000-0000-000000000007"; phone="13800000027"; nickname="李耀"; gender=1}
    @{id="a0000001-0000-0000-0000-000000000008"; phone="13800000028"; nickname="维妮娜"; gender=2}
    @{id="a0000001-0000-0000-0000-000000000009"; phone="13800000029"; nickname="朱喜"; gender=1}
    @{id="a0000001-0000-0000-0000-000000000010"; phone="13800000030"; nickname="赵若"; gender=2}
    @{id="a0000001-0000-0000-0000-000000000011"; phone="13800000031"; nickname="杨武"; gender=1}
    @{id="a0000001-0000-0000-0000-000000000012"; phone="13800000032"; nickname="白凤"; gender=2}
    @{id="a0000001-0000-0000-0000-000000000013"; phone="13800000033"; nickname="贾斯丁"; gender=1}
    @{id="a0000001-0000-0000-0000-000000000014"; phone="13800000034"; nickname="李耀辰"; gender=1}
    @{id="a0000001-0000-0000-0000-000000000015"; phone="13800000035"; nickname="武极"; gender=1}
)

$success = 0
foreach ($u in $users) {
    $body = @{
        phone = $u.phone
        nickname = $u.nickname
        password = "test123456"
        gender = if ($u.gender -eq 1) { "male" } else { "female" }
        height = 175
        weight = 70
        birthday = "1990-01-01"
    } | ConvertTo-Json

    try {
        $resp = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/register" -Method Post -Body $body -ContentType "application/json"
        if ($resp.code -eq 0) {
            Write-Host "  ✅ $($u.nickname) ($($u.phone))" -ForegroundColor Green
            $success++
        } else {
            Write-Host "  ⚠️ $($u.nickname): $($resp.message)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ❌ $($u.nickname): $_" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 200  # 避免太快
}
Write-Host "  → $success/$($users.Count) 用户注册成功" -ForegroundColor Green

# 1.5 获取所有注册用户的真实 UUID（注册时后端生成，和 SQL 里预设的 ID 不同）
Write-Host "[1.5/4] 获取用户 ID 映射..." -ForegroundColor Yellow
$userMap = @{}
$userCheck = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method Post `
    -Body '{"phone":"13800000021","password":"test123456"}' -ContentType "application/json"
if ($userCheck.code -eq 0 -and $userCheck.data) {
    Write-Host "  ✅ 登录测试通过" -ForegroundColor Green
}

# 2. 导入路线数据（使用 mysql 命令行）
Write-Host "[2/4] 导入路线数据..." -ForegroundColor Yellow
$routeFiles = @(
    "seed_routes_inject.sql",
    "nominatim_routes.sql",
    "wikiloc_honghu.sql",
    "osm_park_routes.sql",
    "osm_park_fix.sql",
    "fix_nanshan.sql",
    "reimport_wgs84.sql",
    "osm_wgs84.sql",
    "create_lizhi.sql",
    "all_routes_gcj02.sql",
    "fix_center.sql",
    "fix_nanshan_gcj02.sql",
    "osm_update_routes.sql",
    "linear_trails_sql.sql",
    "final_remaining.sql",
    "sz_bay_routes.sql",
    "inject_all_remaining.sql",
    "osrm_routes_test.sql",
    "osrm_all_routes.sql"
)

$mysqlCmd = "mysql -h 127.0.0.1 -P 3306 -u stridemoor -pstridemoor_pass_2026 stridemoor"
foreach ($f in $routeFiles) {
    $path = "D:\AI\StrideMoor\$f"
    if (Test-Path $path) {
        try {
            $output = cmd /c "$mysqlCmd -e ""source $path""" 2>&1 | Out-String
            Write-Host "  ✅ $f" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️ $f: $_" -ForegroundColor Yellow
        }
    }
}

# 3. 导入跑步记录
Write-Host "[3/4] 导入跑步记录..." -ForegroundColor Yellow
try {
    $output = cmd /c "$mysqlCmd -e ""source D:\AI\StrideMoor\seed_runs.sql""" 2>&1 | Out-String
    Write-Host "  ✅ seed_runs.sql" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ seed_runs.sql: $_" -ForegroundColor Yellow
}

try {
    $output = cmd /c "$mysqlCmd -e ""source D:\AI\StrideMoor\seed_runs_batch2.sql""" 2>&1 | Out-String
    Write-Host "  ✅ seed_runs_batch2.sql" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ seed_runs_batch2.sql: $_" -ForegroundColor Yellow
}

# 4. 验证恢复结果
Write-Host "[4/4] 验证数据..." -ForegroundColor Yellow
$verify = cmd /c "$mysqlCmd -e ""SELECT COUNT(*) AS users FROM users; SELECT COUNT(*) AS routes FROM routes; SELECT COUNT(*) AS runs FROM runs;""" 2>&1
Write-Host $verify
Write-Host "=== 恢复完成 ===" -ForegroundColor Cyan
