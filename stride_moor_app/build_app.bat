@echo off
REM 驰陌 / StrideMoor — 自动构建脚本
REM 自动递增版本号 → flutter clean → flutter build apk --release

cd /d "%~dp0.."
echo ============================================
echo  StrideMoor 构建脚本
echo ============================================

REM 1. 自动递增版本号
echo.
echo [1/4] 递增版本号...
pwsh -NoProfile -File scripts\bump_version.ps1 build
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 版本号递增失败
    exit /b 1
)

REM 2. 清理
echo.
echo [2/4] 清理构建缓存...
call flutter clean >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ⚠  clean 警告（可能已清理过）
)

REM 3. 构建 APK
echo.
echo [3/4] 构建 APK (release)...
call flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 构建失败
    exit /b 1
)

REM 4. 输出信息
echo.
echo [4/4] ✅ 构建完成！
for %%f in (build\app\outputs\flutter-apk\app-release.apk) do echo  APK: %%~ff (%%~zf 字节)

echo.
echo ============================================
