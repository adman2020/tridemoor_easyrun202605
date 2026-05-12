@echo off
chcp 65001 >nul
title 跑境调试工具 - 设境界
echo ====================================
echo  跑境调试工具 · 设境界
echo ====================================
echo.
echo 境界列表:
echo  0=气引  1=筑仙  2=丹凝  3=婴生
echo  4=化神  5=炼虚  6=合元  7=大乘
echo  8=真仙  9=金仙  10=太乙  11=大罗  12=道祖
echo.
set /p realm=输入目标境界 (0-12，直接回车默认 6=合元): 
if "%realm%"=="" set realm=6
echo.
echo 🚀 设为第 %realm% 境...
powershell -ExecutionPolicy Bypass -File "%~dp0debug_set_realm.ps1" -Realm %realm%
echo.
pause
