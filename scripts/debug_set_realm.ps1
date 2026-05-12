param(
    [int]$Realm = 6,
    [int64]$CompanionRuns,
    [int64]$ChallengesWon,
    [int64]$PostCount,
    [int64]$BestMarathonTime,
    [string]$BadgesJSON,
    [switch]$ResetRunData
)

# ============================================
# 跑境调试脚本
# 用法: powershell -ExecutionPolicy Bypass .\debug_set_realm.ps1 -Realm 6
# ============================================

$BASE = "http://localhost:8080/api/v1"
$TOKEN_FILE = "$env:TEMP\stridemoor_debug_token.txt"

# 登录获取 token
function Get-AuthToken {
    # 尝试从缓存读取
    if (Test-Path $TOKEN_FILE) {
        $cached = Get-Content $TOKEN_FILE -Raw
        return $cached.Trim()
    }

    Write-Host "🔑 正在登录..." -ForegroundColor Cyan
    $loginBody = @{
        phone    = "13800000001"
        password = "test123456"
    } | ConvertTo-Json

    $resp = try {
        Invoke-RestMethod -Uri "$BASE/auth/login" -Method Post -Body $loginBody `
            -ContentType "application/json" -ErrorAction Stop
    } catch {
        Write-Host "❌ 登录失败: $_" -ForegroundColor Red
        return $null
    }

    if ($resp.code -ne 0 -or $null -eq $resp.data.tokens.access_token) {
        Write-Host "❌ 登录返回异常: $($resp.message)" -ForegroundColor Red
        return $null
    }

    $token = $resp.data.tokens.access_token
    # 缓存到临时文件
    $token | Out-File -FilePath $TOKEN_FILE -Force
    Write-Host "✅ 登录成功，Token已缓存" -ForegroundColor Green
    return $token
}

# 调用调试接口
$token = Get-AuthToken
if (-not $token) { exit 1 }

$headers = @{
    Authorization = "Bearer $token"
}

$body = @{
    realm = $Realm
} | ConvertTo-Json

Write-Host ""
Write-Host "🚀 设置境界..." -ForegroundColor Yellow
Write-Host "   目标: 第 $Realm 境 ($( @("气引","筑仙","丹凝","婴生","化神","炼虚","合元","大乘","真仙","金仙","太乙","大罗","道祖")[$Realm] ))" -ForegroundColor Gray
Write-Host ""

try {
    $resp = Invoke-RestMethod -Uri "$BASE/admin/realm/debug-set" -Method Post `
        -Body $body -ContentType "application/json" -Headers $headers -ErrorAction Stop

    if ($resp.code -ne 0) {
        Write-Host "❌ 失败: $($resp.message)" -ForegroundColor Red
        exit 1
    }

    Write-Host "✅ 设置成功!" -ForegroundColor Green

    $result = $resp.data.upgrade_result
    $paojing = $resp.data.paojing

    if ($result.upgraded) {
        Write-Host "   晋升: $( @("气引","筑仙","丹凝","婴生","化神","炼虚","合元","大乘","真仙","金仙","太乙","大罗","道祖")[$result.old_realm] ) → $( @("气引","筑仙","丹凝","婴生","化神","炼虚","合元","大乘","真仙","金仙","太乙","大罗","道祖")[$result.new_realm] )" -ForegroundColor Magenta
    } else {
        Write-Host "   保持: $( @("气引","筑仙","丹凝","婴生","化神","炼虚","合元","大乘","真仙","金仙","太乙","大罗","道祖")[$paojing.current_realm] )" -ForegroundColor Magenta
    }

    Write-Host ""
    Write-Host "📋 当前状态:" -ForegroundColor Cyan
    Write-Host "   境界: $($paojing.current_char) · $($paojing.current_name)"
    Write-Host "   已点亮: $( ($paojing.badges | Where-Object { $_.earned }).Count )/13"
    Write-Host "   修炼进度: $($paojing.progress.ToString('P1'))"

    if ($paojing.next_rule) {
        Write-Host ""
        Write-Host "📌 下一境条件:" -ForegroundColor Yellow
        $r = $paojing.next_rule
        if ($r.require_distance) { Write-Host "   单次跑量: $($r.require_distance)km" }
        if ($r.require_marathon_max) { Write-Host "   全马成绩: ≤ $( [math]::Floor($r.require_marathon_max / 60) ):$( ($r.require_marathon_max % 60).ToString('D2') )" }
        if ($r.require_companion_run) { Write-Host "   伴跑次数: $($r.require_companion_run)次" }
        if ($r.require_challenge_win) { Write-Host "   挑战获胜: $($r.require_challenge_win)次" }
        if ($r.require_post) { Write-Host "   发动态: $($r.require_post)次" }
    }

    # 打印徽章列表
    Write-Host ""
    Write-Host "🏅 徽章列表:" -ForegroundColor Cyan
    foreach ($b in $paojing.badges) {
        $icon = if ($b.earned) { "✅" } else { "⬜" }
        $color = if ($b.earned) { "Green" } else { "DarkGray" }
        Write-Host "   $icon $($b.char) · $($b.name)" -ForegroundColor $color
    }

} catch {
    Write-Host "❌ 请求失败: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 可能是后端没启动，先运行启动脚本" -ForegroundColor Yellow
    exit 1
}
